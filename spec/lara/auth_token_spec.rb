# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::AuthToken do
  def fake_jwt(exp_offset: 3600)
    payload = Base64.urlsafe_encode64({ "exp" => (Time.now.to_f + exp_offset).to_i }.to_json,
                                      padding: false)
    "eyJhbGciOiJIUzI1NiJ9.#{payload}.fakesig"
  end

  describe "#initialize" do
    it "normalizes empty string refresh_token to nil" do
      token = described_class.new(fake_jwt, "")
      expect(token.refresh_token).to be_nil
    end

    it "keeps nil refresh_token as nil" do
      token = described_class.new(fake_jwt, nil)
      expect(token.refresh_token).to be_nil
    end

    it "preserves non-empty refresh_token" do
      token = described_class.new(fake_jwt, "my-refresh-token")
      expect(token.refresh_token).to eq("my-refresh-token")
    end
  end
end
