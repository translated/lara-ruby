# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lara::Styleguides do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:styleguides) { described_class.new(client) }

  def styleguide_content
    api_content_fixture("styleguide")
  end

  def stub_get(path, content)
    stub_request(:get, "#{base_url}#{path}").to_return(
      status: 200,
      body: content.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_post(path, content)
    stub_request(:post, "#{base_url}#{path}").to_return(
      status: 200,
      body: content.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_put(path, content)
    stub_request(:put, "#{base_url}#{path}").to_return(
      status: 200,
      body: content.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_delete(path, content)
    stub_request(:delete, "#{base_url}#{path}").to_return(
      status: 200,
      body: content.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  describe "#list" do
    it "returns empty array when no styleguides" do
      stub_get("/v2/styleguides", [])
      expect(styleguides.list).to eq([])
    end

    it "returns array of Styleguide" do
      stub_get("/v2/styleguides", [styleguide_content])
      list = styleguides.list
      expect(list.size).to eq(1)
      expect(list.first).to be_a(Lara::Models::Styleguide)
      expect(list.first.id).to eq("stg_1Bc2De3Fg4Hi5Jk6Lm7No")
      expect(list.first.is_personal).to be(true)
    end
  end

  describe "#create" do
    it "creates with name and content" do
      stub_post("/v2/styleguides", styleguide_content)
      sg = styleguides.create(name: "Test Styleguide", content: "Use a formal tone.")
      expect(sg).to be_a(Lara::Models::Styleguide)
      expect(sg.name).to eq("Test Styleguide")
      expect(sg.content).to eq("Use a formal tone. Prefer British English spelling.")
    end
  end

  describe "#get" do
    it "returns Styleguide when found" do
      styleguide_id = "stg_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_get("/v2/styleguides/#{styleguide_id}", styleguide_content)
      sg = styleguides.get(styleguide_id)
      expect(sg).to be_a(Lara::Models::Styleguide)
      expect(sg.id).to eq(styleguide_id)
    end

    it "returns nil on 404" do
      styleguide_id = "stg_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:get, "#{base_url}/v2/styleguides/#{styleguide_id}").to_return(
        status: 404,
        body: { "type" => "NotFound", "message" => "Not found" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(styleguides.get(styleguide_id)).to be_nil
    end
  end

  describe "#delete" do
    it "returns Styleguide" do
      styleguide_id = "stg_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_delete("/v2/styleguides/#{styleguide_id}", styleguide_content)
      sg = styleguides.delete(styleguide_id)
      expect(sg).to be_a(Lara::Models::Styleguide)
    end
  end

  describe "#update" do
    it "returns updated Styleguide when name is changed" do
      styleguide_id = "stg_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_put("/v2/styleguides/#{styleguide_id}", styleguide_content.merge("name" => "Updated"))
      sg = styleguides.update(styleguide_id, name: "Updated")
      expect(sg.name).to eq("Updated")
    end

    it "returns updated Styleguide when content is changed" do
      styleguide_id = "stg_1Bc2De3Fg4Hi5Jk6Lm7No"
      updated_content = "Use informal tone."
      stub_put("/v2/styleguides/#{styleguide_id}",
               styleguide_content.merge("content" => updated_content))
      sg = styleguides.update(styleguide_id, content: updated_content)
      expect(sg.content).to eq(updated_content)
    end
  end

  it_behaves_like "a shareable resource" do
    let(:resource_api) { styleguides }
    let(:resource_path) { "/v2/styleguides" }
    let(:resource_id) { "stg_1Bc2De3Fg4Hi5Jk6Lm7No" }
    let(:resource_content) { styleguide_content }
    let(:resource_key) { :styleguide }
    let(:resource_model) { Lara::Models::Styleguide }
    let(:shares_model) { Lara::Models::StyleguideShares }
  end
end
