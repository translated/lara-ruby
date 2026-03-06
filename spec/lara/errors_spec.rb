# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::LaraError do
  it "accepts a message and optional status_code" do
    err = described_class.new("Something failed")
    expect(err.message).to eq("Something failed")
    expect(err.status_code).to be_nil
  end

  it "stores status_code when provided" do
    err = described_class.new("Not found", 404)
    expect(err.status_code).to eq(404)
  end
end

RSpec.describe Lara::LaraApiError do
  describe ".from_response" do
    it "builds error from JSON response with error object" do
      response = faraday_response(
        status: 400,
        body: { "error" => { "type" => "ValidationError", "message" => "Invalid parameter" } }
      )
      err = described_class.from_response(response)
      expect(err).to be_a(Lara::LaraApiError)
      expect(err.status_code).to eq(400)
      expect(err.type).to eq("ValidationError")
      expect(err.message).to include("Invalid parameter")
      expect(err.to_s).to include("400")
      expect(err.to_s).to include("ValidationError")
      expect(err.to_s).to include("Invalid parameter")
    end

    it "handles empty or invalid JSON body" do
      response = faraday_response(status: 500, body: "")
      err = described_class.from_response(response)
      expect(err.type).to eq("UnknownError")
      expect(err.message).to include("An unknown error occurred")
    end

    it "handles body without error key" do
      response = faraday_response(status: 502, body: { "foo" => "bar" })
      err = described_class.from_response(response)
      expect(err.type).to eq("UnknownError")
      expect(err.message).to include("An unknown error occurred")
    end
  end

  describe "#initialize" do
    it "sets status_code, type and message" do
      err = described_class.new(404, "NotFound", "Resource not found")
      expect(err.status_code).to eq(404)
      expect(err.type).to eq("NotFound")
      expect(err.message).to include("Resource not found")
    end
  end
end
