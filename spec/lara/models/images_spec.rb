# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::ImageParagraph do
  describe "#initialize" do
    it "accepts text and translation" do
      p = described_class.new(text: "Hello", translation: "Ciao")
      expect(p.text).to eq("Hello")
      expect(p.translation).to eq("Ciao")
      expect(p.adapted_to_matches).to be_nil
      expect(p.glossaries_matches).to be_nil
    end
  end
end

RSpec.describe Lara::Models::ImageTextResult do
  describe ".from_hash" do
    it "returns nil for non-Hash" do
      expect(described_class.from_hash(nil)).to be_nil
      expect(described_class.from_hash("string")).to be_nil
    end

    it "builds result with paragraphs" do
      h = {
        "sourceLanguage" => "en",
        "adaptedTo" => ["mem_1"],
        "glossaries" => ["gls_1"],
        "paragraphs" => [
          { "text" => "Hello", "translation" => "Ciao" },
          { "text" => "World", "translation" => "Mondo" }
        ]
      }
      result = described_class.from_hash(h)
      expect(result.source_language).to eq("en")
      expect(result.adapted_to).to eq(["mem_1"])
      expect(result.glossaries).to eq(["gls_1"])
      expect(result.paragraphs.size).to eq(2)
      expect(result.paragraphs.first).to be_a(Lara::Models::ImageParagraph)
      expect(result.paragraphs.first.text).to eq("Hello")
    end

    it "parses paragraph matches" do
      h = {
        "sourceLanguage" => "en",
        "paragraphs" => [
          {
            "text" => "Hello",
            "translation" => "Ciao",
            "adaptedToMatches" => [
              { "memory" => "mem_1", "language" => "it", "sentence" => "Hello",
                "translation" => "Ciao", "tuid" => "t1" }
            ],
            "glossariesMatches" => [
              { "glossary" => "gls_1", "language" => "it", "term" => "Hello",
                "translation" => "Ciao" }
            ]
          }
        ]
      }
      result = described_class.from_hash(h)
      paragraph = result.paragraphs.first
      expect(paragraph.adapted_to_matches).to be_an(Array)
      expect(paragraph.adapted_to_matches.first).to be_a(Lara::Models::NGMemoryMatch)
      expect(paragraph.adapted_to_matches.first.memory).to eq("mem_1")
      expect(paragraph.glossaries_matches).to be_an(Array)
      expect(paragraph.glossaries_matches.first).to be_a(Lara::Models::NGGlossaryMatch)
    end

    it "handles empty paragraphs" do
      h = { "sourceLanguage" => "en", "paragraphs" => [] }
      result = described_class.from_hash(h)
      expect(result.paragraphs).to eq([])
    end

    it "handles nil matches in paragraphs" do
      h = {
        "sourceLanguage" => "en",
        "paragraphs" => [
          { "text" => "Hello", "translation" => "Ciao",
            "adaptedToMatches" => nil, "glossariesMatches" => nil }
        ]
      }
      result = described_class.from_hash(h)
      expect(result.paragraphs.first.adapted_to_matches).to be_nil
      expect(result.paragraphs.first.glossaries_matches).to be_nil
    end
  end
end
