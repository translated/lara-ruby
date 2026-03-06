# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::AudioTranslator do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:s3_double) do
    double("S3Client").tap do |s3|
      allow(s3).to receive(:upload).and_return(nil)
      allow(s3).to receive(:download).and_return("translated audio bytes")
    end
  end
  let(:audio) { described_class.new(client, s3_double) }

  let(:audio_id) { "aud_4Ef5Gh6Ij7Kl8Mn9Op0Qr" }

  def audio_content
    api_content_fixture("audio")
  end

  describe "#upload" do
    it "fetches upload-url, uploads to S3, posts audio and returns Audio" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "s3key-1" } }
      stub_request(:get, "#{base_url}/v2/audio/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/audio/translate").to_return(
        status: 200,
        body: { "content" => audio_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["audio", ".mp3"]) do |f|
        f.write("audio content")
        f.rewind
        result = audio.upload(file_path: f.path, filename: "test.mp3", target: "it", source: "en")
        expect(result).to be_a(Lara::Models::Audio)
        expect(result.id).to eq(audio_id)
        expect(result.status).to eq("translated")
        expect(s3_double).to have_received(:upload).with(url: upload_url_response["url"],
                                                         fields: upload_url_response["fields"], io: f.path)
      end
    end

    it "sends X-No-Trace when no_trace true" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      stub_request(:get, "#{base_url}/v2/audio/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/audio/translate").to_return(
        status: 200,
        body: { "content" => audio_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["audio", ".mp3"]) do |f|
        f.rewind
        audio.upload(file_path: f.path, filename: "x.mp3", target: "it", no_trace: true)
        expect(WebMock).to have_requested(:post,
                                          "#{base_url}/v2/audio/translate").with(headers: { "X-No-Trace" => "true" })
      end
    end
  end

  describe "#status" do
    it "returns Audio" do
      stub_request(:get, "#{base_url}/v2/audio/#{audio_id}").to_return(
        status: 200,
        body: { "content" => audio_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      result = audio.status(audio_id)
      expect(result).to be_a(Lara::Models::Audio)
      expect(result.id).to eq(audio_id)
    end
  end

  describe "#download" do
    it "fetches download-url and returns S3 download body" do
      download_url = "https://s3-fake.example.com/download/#{audio_id}"
      stub_request(:get, "#{base_url}/v2/audio/#{audio_id}/download-url").to_return(
        status: 200,
        body: { "content" => { "url" => download_url } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      result = audio.download(audio_id)
      expect(result).to eq("translated audio bytes")
      expect(s3_double).to have_received(:download).with(url: download_url)
    end
  end

  describe "#translate" do
    it "uploads, polls until translated, downloads and returns bytes" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      download_url = "https://s3-fake.example.com/download/#{audio_id}"
      stub_request(:get, "#{base_url}/v2/audio/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/audio/translate").to_return(
        status: 200,
        body: { "content" => audio_content.merge("status" => "translated") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/audio/#{audio_id}").to_return(
        status: 200,
        body: { "content" => audio_content.merge("status" => "translated") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/audio/#{audio_id}/download-url").to_return(
        status: 200,
        body: { "content" => { "url" => download_url } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      audio.instance_variable_set(:@polling_interval, 0)
      Tempfile.create(["audio", ".mp3"]) do |f|
        f.rewind
        result = audio.translate(file_path: f.path, filename: "test.mp3", target: "it")
        expect(result).to eq("translated audio bytes")
      end
    end

    it "raises LaraApiError when status becomes error" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      stub_request(:get, "#{base_url}/v2/audio/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/audio/translate").to_return(
        status: 200,
        body: { "content" => audio_content.merge("status" => "initialized") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/audio/#{audio_id}").to_return(
        status: 200,
        body: { "content" => audio_content.merge("status" => "error",
                                                 "error_reason" => "Audio processing failed") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      audio.instance_variable_set(:@polling_interval, 0)
      Tempfile.create(["audio", ".mp3"]) do |f|
        f.rewind
        expect { audio.translate(file_path: f.path, filename: "test.mp3", target: "it") }
          .to raise_error(Lara::LaraApiError, /Audio processing failed/)
      end
    end
  end
end
