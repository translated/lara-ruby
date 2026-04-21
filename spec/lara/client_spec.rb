# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Client do
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:base_url) { "https://api.laratranslate.com" }
  let(:client) { described_class.new(credentials, base_url: base_url) }

  def stub_api(method, path, response_body:, content_type: "application/json",
               status: 200)
    url = if path.start_with?("http")
            path
          else
            "#{base_url}#{path.start_with?('/') ? path : "/#{path}"}"
          end
    stub_request(method.downcase.to_sym, url).to_return(
      status: status,
      body: response_body.is_a?(Hash) ? response_body.to_json : response_body,
      headers: { "Content-Type" => content_type }
    )
  end

  describe "#initialize" do
    it "uses DEFAULT_BASE_URL when not provided" do
      c = described_class.new(credentials)
      expect(c.base_url).to eq(described_class::DEFAULT_BASE_URL)
    end

    it "uses given base_url" do
      expect(client.base_url).to eq(base_url)
    end
  end

  describe "#get" do
    it "returns content from JSON response" do
      stub_api("GET", "/languages", response_body: { "content" => %w[en-US it-IT fr-FR] })
      result = client.get("/languages")
      expect(result).to eq(%w[en-US it-IT fr-FR])
    end

    it "normalizes path with leading slash" do
      stub_api("GET", "/languages", response_body: { "content" => [] })
      client.get("languages")
      expect(WebMock).to have_requested(:get, "#{base_url}/languages")
    end
  end

  describe "#post" do
    it "returns content from JSON response" do
      stub_api("POST", "/translate", response_body: { "content" => { "translation" => "ok" } })
      result = client.post("/translate", body: { q: "hello", target: "it" })
      expect(result).to eq("translation" => "ok")
    end
  end

  describe "#put" do
    it "returns content from JSON response" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_api("PUT", "/memories/#{memory_id}",
               response_body: { "content" => { "id" => memory_id, "name" => "New" } })
      result = client.put("/memories/#{memory_id}", body: { name: "New" })
      expect(result).to include("id" => memory_id, "name" => "New")
    end
  end

  describe "#delete" do
    it "returns content from JSON response" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_api("DELETE", "/memories/#{memory_id}", response_body: { "content" => { "id" => memory_id } })
      result = client.delete("/memories/#{memory_id}")
      expect(result).to include("id" => memory_id)
    end
  end

  describe "error handling" do
    it "raises LaraApiError on API error response" do
      stub_api("POST", "/translate",
               response_body: { "error" => { "type" => "ValidationError", "message" => "Bad request" } }, status: 400)
      expect { client.post("/translate", body: {}) }.to raise_error(Lara::LaraApiError) do |e|
        expect(e.status_code).to eq(400)
        expect(e.type).to eq("ValidationError")
        expect(e.message).to include("Bad request")
      end
    end

    it "returns raw body for CSV content-type" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:get, "#{base_url}/glossaries/#{glossary_id}/export")
        .with(query: { "content_type" => "csv/table-uni" })
        .to_return(status: 200, body: "term,translation\nhello,ciao",
                   headers: { "Content-Type" => "text/csv" })
      result = client.get("/glossaries/#{glossary_id}/export", params: { content_type: "csv/table-uni" })
      expect(result).to eq("term,translation\nhello,ciao")
    end
  end

  describe "request headers" do
    it "uses correct HTTP method for get requests" do
      stub_api("GET", "/languages", response_body: { "content" => [] })
      client.get("/languages")
      expect(WebMock).to have_requested(:get, "#{base_url}/languages")
    end

    it "sends Authorization with Bearer prefix" do
      stub_api("POST", "/translate", response_body: { "content" => {} })
      client.post("/translate", body: { q: "x", target: "it" })
      expect(WebMock).to(have_requested(:post, "#{base_url}/translate")
        .with { |req| req.headers["Authorization"]&.start_with?("Bearer ") })
    end
  end

  describe "authentication" do
    it "initializes with AuthToken and skips authenticate" do
      payload = Base64.urlsafe_encode64({ "exp" => (Time.now.to_f + 3600).to_i }.to_json, padding: false)
      fake_jwt = "eyJhbGciOiJIUzI1NiJ9.#{payload}.fakesig"
      token = Lara::AuthToken.new(fake_jwt, "refresh-token")
      c = described_class.new(token, base_url: base_url)
      stub_api("GET", "/test", response_body: { "result" => "ok" })
      result = c.get("/test")
      expect(result).to eq("result" => "ok")
      expect(WebMock).not_to have_requested(:post, %r{/v2/auth})
    end

    it "raises ArgumentError for invalid auth_method" do
      expect { described_class.new("invalid") }.to raise_error(ArgumentError, /auth_method/)
    end

    it "retries on 401 jwt expired by refreshing token" do
      stub_request(:post, "#{base_url}/test").to_return(
        { status: 401,
          body: { "error" => { "type" => "AuthError", "message" => "jwt expired" } }.to_json,
          headers: { "Content-Type" => "application/json" } },
        { status: 200,
          body: { "result" => "success" }.to_json,
          headers: { "Content-Type" => "application/json" } }
      )
      stub_request(:post, "#{base_url}/v2/auth/refresh").to_return(
        status: 200,
        body: { "token" => "new-jwt" }.to_json,
        headers: { "Content-Type" => "application/json", "x-lara-refresh-token" => "new-refresh" }
      )
      result = client.post("/test", body: { q: "x" })
      expect(result).to eq("result" => "success")
    end

    it "raises non-jwt-expired 401 without retrying" do
      stub_request(:post, "#{base_url}/test").to_return(
        status: 401,
        body: { "error" => { "type" => "AuthError", "message" => "invalid token" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect { client.post("/test", body: { q: "x" }) }.to raise_error(Lara::LaraApiError) do |e|
        expect(e.status_code).to eq(401)
        expect(e.message).to include("invalid token")
      end
    end

    it "returns raw_response body when raw_response is true" do
      stub_request(:post, "#{base_url}/v2/images/translate").to_return(
        status: 200,
        body: "raw-binary-data",
        headers: { "Content-Type" => "image/png" }
      )
      result = client.post("/v2/images/translate", body: { target: "it" }, raw_response: true)
      expect(result).to eq("raw-binary-data")
    end
  end

  describe "streaming" do
    it "parses NDJSON streaming response when callback given" do
      stream_body = "{\"content\":{\"translation\":\"partial\"}}\n{\"content\":{\"translation\":\"Ciao\"}}\n"
      stub_api("POST", "/translate", response_body: stream_body)
      results = []
      client.post("/translate", body: { q: "Hello", target: "it", reasoning: true }) do |partial|
        results << partial
      end
      expect(results.size).to eq(2)
      expect(results.last).to eq("translation" => "Ciao")
    end

    it "returns last result from streaming response" do
      stream_body = "{\"content\":{\"translation\":\"Ciao\"}}\n"
      stub_api("POST", "/translate", response_body: stream_body)
      result = client.post("/translate", body: { q: "Hello", target: "it", reasoning: true })
      expect(result).to eq("translation" => "Ciao")
    end
  end
end
