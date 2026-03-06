# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Translator do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:translator) do
    described_class.new(access_key_id: "test-id", access_key_secret: "test-secret",
                        base_url: base_url)
  end

  def stub_translate(body)
    stub_request(:post, "#{base_url}/translate").to_return(
      status: 200,
      body: { "content" => body }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_languages(content)
    stub_request(:post, "#{base_url}/languages").to_return(
      status: 200,
      body: { "content" => content }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  describe "#initialize" do
    it "accepts credentials object" do
      creds = Lara::Credentials.new("id", "secret")
      stub_request(:post, %r{#{Regexp.escape(base_url)}/languages}).to_return(
        body: { "content" => [] }.to_json, headers: { "Content-Type" => "application/json" }
      )
      t = described_class.new(credentials: creds)
      expect(t.client).to be_a(Lara::Client)
      expect(t.memories).to be_a(Lara::Memories)
      expect(t.glossaries).to be_a(Lara::Glossaries)
      expect(t.documents).to be_a(Lara::Documents)
    end

    it "accepts access_key_id and access_key_secret" do
      stub_request(:post, %r{#{Regexp.escape(base_url)}/}).to_return(
        body: { "content" => [] }.to_json, headers: { "Content-Type" => "application/json" }
      )
      t = described_class.new(access_key_id: "id", access_key_secret: "secret")
      expect(t.client).to be_a(Lara::Client)
    end

    it "raises ArgumentError when neither credentials nor keys provided" do
      expect do
        described_class.new(access_key_id: "id")
      end.to raise_error(ArgumentError,
                         /credentials or access_key_id/)
      expect do
        described_class.new(access_key_secret: "secret")
      end.to raise_error(ArgumentError,
                         /credentials or access_key_id/)
      expect { described_class.new }.to raise_error(ArgumentError, /credentials or access_key_id/)
    end
  end

  describe "#translate" do
    it "translates string and returns TextResult" do
      stub_translate("translation" => "Ciao", "source_language" => "en",
                     "content_type" => "text/plain")
      result = translator.translate("Hello", target: "it")
      expect(result).to be_a(Lara::Models::TextResult)
      expect(result.translation).to eq("Ciao")
      expect(result.source_language).to eq("en")
    end

    it "translates array of strings" do
      stub_translate("translation" => %w[Ciao mondo], "source_language" => "en",
                     "content_type" => "text/plain")
      result = translator.translate(%w[Hello world], target: "it")
      expect(result.translation).to eq(%w[Ciao mondo])
    end

    it "translates array of TextBlock" do
      stub_translate("translation" => %w[Ciao mondo], "source_language" => "en",
                     "content_type" => "text/plain")
      blocks = [Lara::Models::TextBlock.new(text: "Hello", translatable: true),
                Lara::Models::TextBlock.new(text: "world", translatable: false)]
      result = translator.translate(blocks, target: "it")
      expect(result.translation).to eq(%w[Ciao mondo])
    end

    it "sends no_trace header when no_trace true" do
      stub_translate("translation" => "x", "source_language" => "en",
                     "content_type" => "text/plain")
      translator.translate("x", target: "it", no_trace: true)
      expect(WebMock).to have_requested(:post,
                                        "#{base_url}/translate").with(headers: { "X-No-Trace" => "true" })
    end

    it "maps use_cache true to yes and false to no" do
      stub_translate("translation" => "x", "source_language" => "en",
                     "content_type" => "text/plain")
      translator.translate("x", target: "it", use_cache: true)
      expect(WebMock).to(have_requested(:post, "#{base_url}/translate").with do |req|
        body = JSON.parse(req.body)
        body["use_cache"] == "yes"
      end)
    end

    it "raises ArgumentError for non-string non-array text" do
      expect do
        translator.translate(123, target: "it")
      end.to raise_error(ArgumentError, /string or an iterable/)
    end

    it "raises ArgumentError for mixed array" do
      expect do
        translator.translate(["a", 1], target: "it")
      end.to raise_error(ArgumentError, /TextBlock objects/)
    end
  end

  describe "#get_languages" do
    it "returns list of supported language codes" do
      stub_languages(%w[en-US it-IT fr-FR])
      result = translator.get_languages
      expect(result).to eq(%w[en-US it-IT fr-FR])
    end
  end

  describe "attr_readers" do
    it "exposes client, memories, glossaries, documents" do
      stub_request(:post, %r{#{Regexp.escape(base_url)}/}).to_return(
        body: { "content" => [] }.to_json, headers: { "Content-Type" => "application/json" }
      )
      t = described_class.new(access_key_id: "a", access_key_secret: "b")
      expect(t.client).to be_a(Lara::Client)
      expect(t.memories).to be_a(Lara::Memories)
      expect(t.glossaries).to be_a(Lara::Glossaries)
      expect(t.documents).to be_a(Lara::Documents)
    end
  end
end
