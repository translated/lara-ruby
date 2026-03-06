# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::Documents do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:s3_double) do
    double("S3Client").tap do |s3|
      allow(s3).to receive(:upload).and_return(nil)
      allow(s3).to receive(:download).and_return("translated file bytes")
    end
  end
  let(:documents) { described_class.new(client, s3_double) }

  let(:document_id) { "doc_2Cd3Ef4Gh5Ij6Kl7Mn8Op" }

  def doc_content
    api_content_fixture("document")
  end

  describe "#upload" do
    it "fetches upload-url, uploads to S3, posts document and returns Document" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "s3key-1" } }
      stub_request(:get, "#{base_url}/v2/documents/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/documents").to_return(
        status: 200,
        body: { "content" => doc_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["doc", ".docx"]) do |f|
        f.write("content")
        f.rewind
        doc = documents.upload(file_path: f.path, filename: "test.docx", target: "it", source: "en")
        expect(doc).to be_a(Lara::Models::Document)
        expect(doc.id).to eq(document_id)
        expect(doc.status).to eq("translated")
        expect(s3_double).to have_received(:upload).with(url: upload_url_response["url"],
                                                         fields: upload_url_response["fields"], io: f.path)
      end
    end

    it "sends X-No-Trace when no_trace true" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      stub_request(:get, "#{base_url}/v2/documents/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/documents").to_return(
        status: 200,
        body: { "content" => doc_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["doc", ".docx"]) do |f|
        f.rewind
        documents.upload(file_path: f.path, filename: "x.docx", target: "it", no_trace: true)
        expect(WebMock).to have_requested(:post,
                                          "#{base_url}/v2/documents").with(headers: { "X-No-Trace" => "true" })
      end
    end
  end

  describe "#status" do
    it "returns Document" do
      stub_request(:get, "#{base_url}/v2/documents/#{document_id}").to_return(
        status: 200,
        body: { "content" => doc_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      doc = documents.status(document_id)
      expect(doc).to be_a(Lara::Models::Document)
      expect(doc.id).to eq(document_id)
      expect(doc.status).to eq("translated")
    end
  end

  describe "#download" do
    it "fetches download-url and returns S3 download body" do
      download_url = "https://s3-fake.example.com/download/#{document_id}"
      stub_request(:get, "#{base_url}/v2/documents/#{document_id}/download-url").to_return(
        status: 200,
        body: { "content" => { "url" => download_url } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      result = documents.download(document_id)
      expect(result).to eq("translated file bytes")
      expect(s3_double).to have_received(:download).with(url: download_url)
    end
  end

  describe "#translate" do
    it "uploads, polls until translated, downloads and returns bytes" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      download_url = "https://s3-fake.example.com/download/#{document_id}"
      stub_request(:get, "#{base_url}/v2/documents/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/documents").to_return(
        status: 200,
        body: { "content" => doc_content.merge("status" => "translated") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/documents/#{document_id}").to_return(
        status: 200,
        body: { "content" => doc_content.merge("status" => "translated") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/documents/#{document_id}/download-url").to_return(
        status: 200,
        body: { "content" => { "url" => download_url } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      documents.instance_variable_set(:@polling_interval, 0)
      Tempfile.create(["doc", ".docx"]) do |f|
        f.rewind
        result = documents.translate(file_path: f.path, filename: "test.docx", target: "it")
        expect(result).to eq("translated file bytes")
      end
    end

    it "raises LaraApiError when status becomes error" do
      upload_url_response = { "url" => "https://s3-fake.example.com/upload", "fields" => { "key" => "k1" } }
      stub_request(:get, "#{base_url}/v2/documents/upload-url")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { "content" => upload_url_response }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "#{base_url}/v2/documents").to_return(
        status: 200,
        body: { "content" => doc_content.merge("id" => document_id,
                                               "status" => "initialized") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "#{base_url}/v2/documents/#{document_id}").to_return(
        status: 200,
        body: { "content" => doc_content.merge("id" => document_id, "status" => "error",
                                               "error_reason" => "Conversion failed") }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      documents.instance_variable_set(:@polling_interval, 0)
      Tempfile.create(["doc", ".docx"]) do |f|
        f.rewind
        expect { documents.translate(file_path: f.path, filename: "test.docx", target: "it") }
          .to raise_error(Lara::LaraApiError, /Conversion failed/)
      end
    end
  end
end
