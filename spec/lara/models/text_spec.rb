# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::TextBlock do
  describe "#initialize" do
    it "accepts text and translatable" do
      tb = described_class.new(text: "Hello", translatable: true)
      expect(tb.text).to eq("Hello")
      expect(tb.translatable).to eq(true)
    end

    it "defaults translatable to true" do
      tb = described_class.new(text: "Hi")
      expect(tb.translatable).to eq(true)
    end

    it "coerces translatable to boolean" do
      tb = described_class.new(text: "x", translatable: false)
      expect(tb.translatable).to eq(false)
    end
  end
end

RSpec.describe Lara::Models::TextResult do
  describe ".from_hash" do
    it "returns nil for nil" do
      expect(described_class.from_hash(nil)).to be_nil
    end

    it "returns nil for non-Hash" do
      expect(described_class.from_hash([])).to be_nil
    end

    it "builds result with string translation" do
      h = {
        "translation" => "Ciao",
        "source_language" => "en",
        "content_type" => "text/plain",
        "adapted_to" => nil,
        "glossaries" => nil,
        "adapted_to_matches" => nil,
        "glossaries_matches" => nil
      }
      result = described_class.from_hash(h)
      expect(result.translation).to eq("Ciao")
      expect(result.source_language).to eq("en")
      expect(result.content_type).to eq("text/plain")
    end

    it "builds result with array of strings translation" do
      h = {
        "translation" => %w[Ciao mondo],
        "source_language" => "en",
        "content_type" => "text/plain"
      }
      result = described_class.from_hash(h)
      expect(result.translation).to eq(%w[Ciao mondo])
    end

    it "builds result with array of TextBlock-like hashes" do
      h = {
        "translation" => [
          { "text" => "Hello", "translatable" => true },
          { "text" => "world", "translatable" => false }
        ],
        "source_language" => "en",
        "content_type" => "text/plain"
      }
      result = described_class.from_hash(h)
      expect(result.translation).to be_an(Array)
      expect(result.translation.size).to eq(2)
      expect(result.translation[0]).to be_a(Lara::Models::TextBlock)
      expect(result.translation[0].text).to eq("Hello")
      expect(result.translation[0].translatable).to eq(true)
      expect(result.translation[1].text).to eq("world")
      expect(result.translation[1].translatable).to eq(false)
    end

    it "parses adapted_to_matches and glossaries_matches" do
      h = {
        "translation" => "Ok",
        "source_language" => "en",
        "content_type" => "text/plain",
        "adapted_to_matches" => [
          { "memory" => "m1", "language" => "en", "sentence" => "x", "translation" => "y",
            "tuid" => nil }
        ],
        "glossaries_matches" => [
          { "glossary" => "g1", "language" => "en", "term" => "a", "translation" => "b" }
        ]
      }
      result = described_class.from_hash(h)
      expect(result.adapted_to_matches).to be_an(Array)
      expect(result.adapted_to_matches.first).to be_a(Lara::Models::NGMemoryMatch)
      expect(result.glossaries_matches).to be_an(Array)
      expect(result.glossaries_matches.first).to be_a(Lara::Models::NGGlossaryMatch)
    end

    it "handles nil matches" do
      h = {
        "translation" => "Ok",
        "source_language" => "en",
        "content_type" => "text/plain",
        "adapted_to_matches" => nil,
        "glossaries_matches" => nil
      }
      result = described_class.from_hash(h)
      expect(result.adapted_to_matches).to be_nil
      expect(result.glossaries_matches).to be_nil
    end
  end
end
