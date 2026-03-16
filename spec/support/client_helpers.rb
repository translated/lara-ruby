# frozen_string_literal: true

module ClientHelpers
  def test_credentials
    Lara::Credentials.new("test-key-id", "test-key-secret")
  end

  def test_base_url
    "https://api.example.com"
  end

  def api_client
    Lara::Client.new(test_credentials, base_url: test_base_url)
  end

  def fixture_path(name)
    File.join(__dir__, "..", "fixtures", "#{name}.json")
  end

  def fixture_content(name)
    File.read(fixture_path(name))
  end

  def json_fixture(name)
    JSON.parse(fixture_content(name))
  end

  def api_content_fixture(name)
    json_fixture(name)["content"]
  end

  def faraday_response(status: 200, body: {}, headers: { "Content-Type" => "application/json" })
    double(
      "response",
      success?: status >= 200 && status < 300,
      status: status,
      body: body.is_a?(Hash) ? body.to_json : body,
      headers: headers
    )
  end
end

RSpec.configure do |config|
  config.include ClientHelpers

  config.before(:each) do
    stub_request(:post, %r{/v2/auth\z}).to_return(
      status: 200,
      body: { "token" => "fake-jwt-token" }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "x-lara-refresh-token" => "fake-refresh-token"
      }
    )

    stub_request(:post, %r{/v2/auth/refresh\z}).to_return(
      status: 200,
      body: { "token" => "fake-jwt-token" }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "x-lara-refresh-token" => "fake-refresh-token"
      }
    )
  end
end
