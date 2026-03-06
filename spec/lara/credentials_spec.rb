# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Credentials do
  describe "#initialize" do
    it "accepts access_key_id and access_key_secret" do
      creds = described_class.new("my-id", "my-secret")
      expect(creds.access_key_id).to eq("my-id")
      expect(creds.access_key_secret).to eq("my-secret")
    end
  end

  describe "attr_readers" do
    it "exposes access_key_id and access_key_secret" do
      creds = described_class.new("id-123", "secret-456")
      expect(creds.access_key_id).to eq("id-123")
      expect(creds.access_key_secret).to eq("secret-456")
    end
  end
end
