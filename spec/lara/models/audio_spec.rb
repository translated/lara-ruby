# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::AudioStatus do
  describe "defines expected constants" do
    it "has all status values" do
      expect(described_class::ALL).to include("initialized", "analyzing", "paused",
                                              "ready", "translating", "translated", "error")
    end
  end

  describe ".valid?" do
    it "returns true for known statuses" do
      described_class::ALL.each do |status|
        expect(described_class.valid?(status)).to be true
      end
    end

    it "returns false for unknown value" do
      expect(described_class.valid?("unknown")).to be false
    end
  end
end

RSpec.describe Lara::Models::Audio do
  describe "#initialize" do
    it "accepts required and optional attributes" do
      audio = described_class.new(
        id: "aud_1",
        status: "translated",
        filename: "test.mp3",
        target: "it",
        source: "en",
        created_at: "2024-01-15T10:00:00Z",
        updated_at: "2024-01-15T10:05:00Z",
        translated_seconds: 120.5,
        total_seconds: 200.0,
        error_reason: nil
      )
      expect(audio.id).to eq("aud_1")
      expect(audio.status).to eq("translated")
      expect(audio.filename).to eq("test.mp3")
      expect(audio.target).to eq("it")
      expect(audio.source).to eq("en")
      expect(audio.created_at).to be_a(Time)
      expect(audio.translated_seconds).to eq(120.5)
      expect(audio.total_seconds).to eq(200.0)
      expect(audio.error_reason).to be_nil
    end
  end
end
