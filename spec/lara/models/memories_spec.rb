# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::Memory do
  describe "#initialize" do
    it "accepts required and optional attributes" do
      m = described_class.new(
        id: "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn",
        name: "My Memory",
        owner_id: "acc_1XyZ2Ab3Cd4Ef5Gh6Ij7Kl",
        created_at: "2024-01-15T10:00:00Z",
        updated_at: "2024-01-15T11:00:00Z",
        external_id: "ext_3De4Fg5Hi6Jk7Lm8No9Pq",
        secret: nil,
        collaborators_count: 0,
        shared_at: nil
      )
      expect(m.id).to eq("mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn")
      expect(m.name).to eq("My Memory")
      expect(m.owner_id).to eq("acc_1XyZ2Ab3Cd4Ef5Gh6Ij7Kl")
      expect(m.created_at).to be_a(Time)
      expect(m.updated_at).to be_a(Time)
      expect(m.external_id).to eq("ext_3De4Fg5Hi6Jk7Lm8No9Pq")
    end
  end
end

RSpec.describe Lara::Models::MemoryImport do
  describe "#initialize" do
    it "accepts range_begin and range_end" do
      imp = described_class.new(
        id: "imp-1",
        channel: "main",
        size: 100,
        progress: 0.5,
        range_begin: 0,
        range_end: 100
      )
      expect(imp.range_begin).to eq(0)
      expect(imp.range_end).to eq(100)
    end

    it "accepts begin/end from kwargs for range" do
      h = { id: "imp-1", channel: "main", size: 50, progress: 1.0 }
      h[:begin] = 0
      h[:end] = 50
      imp = described_class.new(**h)
      expect(imp.range_begin).to eq(0)
      expect(imp.range_end).to eq(50)
    end
  end
end
