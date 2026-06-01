# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::Images do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:images) { described_class.new(client) }

  describe "#translate" do
    it "posts image as multipart and returns raw binary response" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "translated-image-bytes",
        headers: { "Content-Type" => "image/png" }
      )
      Tempfile.create(["img", ".png"]) do |f|
        f.write("PNG image data")
        f.rewind
        result = images.translate(file_path: f.path, target: "it")
        expect(result).to eq("translated-image-bytes")
      end
    end

    it "sends X-No-Trace when no_trace true" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "bytes",
        headers: { "Content-Type" => "image/png" }
      )
      Tempfile.create(["img", ".png"]) do |f|
        f.rewind
        images.translate(file_path: f.path, target: "it", no_trace: true)
        expect(WebMock).to have_requested(:post,
                                          "#{base_url}/v2/images/translate").with(headers: { "X-No-Trace" => "true" })
      end
    end

    it "sends model param when model is provided" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "bytes",
        headers: { "Content-Type" => "image/png" }
      )
      Tempfile.create(["img", ".png"]) do |f|
        f.rewind
        images.translate(file_path: f.path, target: "it", model: Lara::Models::ImageTranslationModel::GENERATIVE)
        expect(WebMock).to(have_requested(:post, "#{base_url}/v2/images/translate").with do |req|
          req.body.include?("generative")
        end)
      end
    end

    it "falls back to text_removal when model is not provided (backward compat)" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "bytes",
        headers: { "Content-Type" => "image/png" }
      )
      Tempfile.create(["img", ".png"]) do |f|
        f.rewind
        images.translate(file_path: f.path, target: "it", text_removal: "inpainting")
        expect(WebMock).to(have_requested(:post, "#{base_url}/v2/images/translate").with do |req|
          req.body.include?("inpainting")
        end)
      end
    end

    it "prefers model over text_removal when both are provided" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "bytes",
        headers: { "Content-Type" => "image/png" }
      )
      Tempfile.create(["img", ".png"]) do |f|
        f.rewind
        images.translate(file_path: f.path, target: "it",
                         model: Lara::Models::ImageTranslationModel::GENERATIVE_FAST,
                         text_removal: "overlay")
        expect(WebMock).to(have_requested(:post, "#{base_url}/v2/images/translate").with do |req|
          req.body.include?("generative_fast")
        end)
      end
    end
  end

  describe "#translate_text" do
    it "returns ImageTextResult with paragraphs" do
      response_content = {
        "sourceLanguage" => "en",
        "paragraphs" => [
          { "text" => "Hello", "translation" => "Ciao" },
          { "text" => "World", "translation" => "Mondo" }
        ]
      }
      stub_request(:post, "#{base_url}/v2/images/translate-text").to_return(
        status: 200,
        body: response_content.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["img", ".jpg"]) do |f|
        f.write("JPEG image data")
        f.rewind
        result = images.translate_text(file_path: f.path, target: "it")
        expect(result).to be_a(Lara::Models::ImageTextResult)
        expect(result.source_language).to eq("en")
        expect(result.paragraphs.size).to eq(2)
        expect(result.paragraphs.first.text).to eq("Hello")
        expect(result.paragraphs.first.translation).to eq("Ciao")
      end
    end

    it "parses paragraphs with matches" do
      response_content = {
        "sourceLanguage" => "en",
        "paragraphs" => [
          {
            "text" => "Hello",
            "translation" => "Ciao",
            "adaptedToMatches" => [
              { "memory" => "mem_1", "language" => "it", "sentence" => "Hello",
                "translation" => "Ciao" }
            ],
            "glossariesMatches" => [
              { "glossary" => "gls_1", "language" => "it", "term" => "Hello",
                "translation" => "Ciao" }
            ]
          }
        ]
      }
      stub_request(:post, "#{base_url}/v2/images/translate-text").to_return(
        status: 200,
        body: response_content.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["img", ".jpg"]) do |f|
        f.rewind
        result = images.translate_text(file_path: f.path, target: "it")
        paragraph = result.paragraphs.first
        expect(paragraph.adapted_to_matches.size).to eq(1)
        expect(paragraph.adapted_to_matches.first).to be_a(Lara::Models::NGMemoryMatch)
        expect(paragraph.glossaries_matches.size).to eq(1)
        expect(paragraph.glossaries_matches.first).to be_a(Lara::Models::NGGlossaryMatch)
      end
    end
  end
end
