# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::DocumentStatus do
  it "defines expected constants" do
    expect(described_class::INITIALIZED).to eq("initialized")
    expect(described_class::ANALYZING).to eq("analyzing")
    expect(described_class::PAUSED).to eq("paused")
    expect(described_class::READY).to eq("ready")
    expect(described_class::TRANSLATING).to eq("translating")
    expect(described_class::TRANSLATED).to eq("translated")
    expect(described_class::ERROR).to eq("error")
  end

  describe ".valid?" do
    it "returns true for known statuses" do
      expect(described_class.valid?("translated")).to be true
    end

    it "returns false for unknown value" do
      expect(described_class.valid?("unknown")).to be false
    end
  end
end

RSpec.describe Lara::Models::DocxExtractionParams do
  describe "#to_h" do
    it "returns hash with extract_comments and accept_revisions" do
      p = described_class.new(extract_comments: true, accept_revisions: false)
      expect(p.to_h).to eq(extract_comments: true, accept_revisions: false)
    end

    it "omits nil values" do
      p = described_class.new(extract_comments: nil, accept_revisions: nil)
      expect(p.to_h).to eq({})
    end
  end
end

RSpec.describe Lara::Models::Document do
  describe "#initialize" do
    it "accepts required and optional attributes" do
      doc = described_class.new(
        id: "doc_2Cd3Ef4Gh5Ij6Kl7Mn8Op",
        status: "translated",
        target: "it",
        filename: "file.docx",
        source: "en-US",
        created_at: "2024-01-15T10:00:00Z",
        updated_at: "2024-01-15T11:00:00Z",
        translated_chars: 500,
        total_chars: 500,
        error_reason: nil
      )
      expect(doc.id).to eq("doc_2Cd3Ef4Gh5Ij6Kl7Mn8Op")
      expect(doc.status).to eq("translated")
      expect(doc.target).to eq("it")
      expect(doc.filename).to eq("file.docx")
      expect(doc.source).to eq("en-US")
      expect(doc.translated_chars).to eq(500)
      expect(doc.total_chars).to eq(500)
    end
  end
end
