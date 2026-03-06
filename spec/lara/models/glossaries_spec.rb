# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Models::Glossary do
  describe "#initialize" do
    it "accepts required and optional attributes" do
      g = described_class.new(
        id: "gls_1Bc2De3Fg4Hi5Jk6Lm7No",
        name: "My Glossary",
        owner_id: "acc_1XyZ2Ab3Cd4Ef5Gh6Ij7Kl",
        created_at: "2024-01-15T10:00:00Z",
        updated_at: "2024-01-15T11:00:00Z"
      )
      expect(g.id).to eq("gls_1Bc2De3Fg4Hi5Jk6Lm7No")
      expect(g.name).to eq("My Glossary")
      expect(g.owner_id).to eq("acc_1XyZ2Ab3Cd4Ef5Gh6Ij7Kl")
      expect(g.created_at).to be_a(Time)
      expect(g.updated_at).to be_a(Time)
    end
  end
end

RSpec.describe Lara::Models::GlossaryImport do
  describe "#initialize" do
    it "accepts begin/end from kwargs" do
      h = { id: "imp-1", channel: "main", size: 10, progress: 1.0 }
      h[:begin] = 0
      h[:end] = 10
      imp = described_class.new(**h)
      expect(imp.range_begin).to eq(0)
      expect(imp.range_end).to eq(10)
    end
  end
end

RSpec.describe Lara::Models::GlossaryCounts do
  describe "#initialize" do
    it "accepts unidirectional and multidirectional" do
      c = described_class.new(unidirectional: 5, multidirectional: 3)
      expect(c.unidirectional).to eq(5)
      expect(c.multidirectional).to eq(3)
    end
  end
end
