# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::Base do
  describe ".parse_time" do
    it "parses ISO8601 string to Time" do
      t = described_class.parse_time("2024-01-15T10:00:00Z")
      expect(t).to be_a(Time)
      expect(t.utc?).to be true
    end

    it "returns nil for nil" do
      expect(described_class.parse_time(nil)).to be_nil
    end

    it "returns nil for invalid string" do
      expect(described_class.parse_time("not-a-date")).to be_nil
    end
  end
end
