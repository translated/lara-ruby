# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::Glossaries do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:glossaries) { described_class.new(client) }

  def glossary_content
    api_content_fixture("glossary")
  end

  def stub_get(path, content)
    stub_request(:post, "#{base_url}#{path}").to_return(
      status: 200,
      body: { "content" => content }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_post(path, content)
    stub_request(:post, "#{base_url}#{path}").to_return(
      status: 200,
      body: { "content" => content }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_put(path, content)
    stub_request(:post, "#{base_url}#{path}").to_return(
      status: 200,
      body: { "content" => content }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_delete(path, content)
    stub_request(:post, "#{base_url}#{path}").to_return(
      status: 200,
      body: { "content" => content }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  describe "#list" do
    it "returns empty array when no glossaries" do
      stub_get("/glossaries", [])
      expect(glossaries.list).to eq([])
    end

    it "returns array of Glossary" do
      stub_get("/glossaries", [glossary_content])
      list = glossaries.list
      expect(list.size).to eq(1)
      expect(list.first).to be_a(Lara::Models::Glossary)
      expect(list.first.id).to eq("gls_1Bc2De3Fg4Hi5Jk6Lm7No")
    end
  end

  describe "#create" do
    it "creates with name" do
      stub_post("/glossaries", glossary_content)
      g = glossaries.create(name: "Test Glossary")
      expect(g).to be_a(Lara::Models::Glossary)
      expect(g.name).to eq("Test Glossary")
    end
  end

  describe "#get" do
    it "returns Glossary when found" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_get("/glossaries/#{glossary_id}", glossary_content)
      g = glossaries.get(glossary_id)
      expect(g).to be_a(Lara::Models::Glossary)
      expect(g.id).to eq(glossary_id)
    end

    it "returns nil on 404" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:post, "#{base_url}/glossaries/#{glossary_id}").to_return(
        status: 404,
        body: { "error" => { "type" => "NotFound", "message" => "Not found" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(glossaries.get(glossary_id)).to be_nil
    end
  end

  describe "#delete" do
    it "returns Glossary" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_delete("/glossaries/#{glossary_id}", glossary_content)
      g = glossaries.delete(glossary_id)
      expect(g).to be_a(Lara::Models::Glossary)
    end
  end

  describe "#update" do
    it "returns updated Glossary" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_put("/glossaries/#{glossary_id}", glossary_content.merge("name" => "Updated"))
      g = glossaries.update(glossary_id, name: "Updated")
      expect(g.name).to eq("Updated")
    end
  end

  describe "#counts" do
    it "returns GlossaryCounts" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_get("/glossaries/#{glossary_id}/counts", "unidirectional" => 10, "multidirectional" => 5)
      c = glossaries.counts(glossary_id)
      expect(c).to be_a(Lara::Models::GlossaryCounts)
      expect(c.unidirectional).to eq(10)
      expect(c.multidirectional).to eq(5)
    end
  end

  describe "#import_csv" do
    it "uploads gzipped csv and returns GlossaryImport" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0 }
      stub_request(:post, "#{base_url}/glossaries/#{glossary_id}/import").to_return(
        status: 200,
        body: { "content" => import_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["test", ".csv"]) do |f|
        f.write("term,translation\nhello,ciao")
        f.rewind
        imp = glossaries.import_csv(glossary_id, f.path)
        expect(imp).to be_a(Lara::Models::GlossaryImport)
        expect(imp.id).to eq("imp-1")
      end
    end
  end

  describe "#get_import_status" do
    it "returns GlossaryImport" do
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0.5 }
      stub_get("/glossaries/imports/imp-1", import_content)
      imp = glossaries.get_import_status("imp-1")
      expect(imp.progress).to eq(0.5)
    end
  end

  describe "#wait_for_import" do
    it "polls until progress is 1.0" do
      import_initial = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0.5 }
      import_done = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 1.0 }
      stub_request(:post, "#{base_url}/glossaries/imports/imp-1").to_return(
        {
          status: 200,
          body: { "content" => import_initial }.to_json,
          headers: { "Content-Type" => "application/json" }
        },
        {
          status: 200,
          body: { "content" => import_done }.to_json,
          headers: { "Content-Type" => "application/json" }
        }
      )
      glossaries.instance_variable_set(:@polling_interval, 0)
      current = Lara::Models::GlossaryImport.new(**import_initial.transform_keys(&:to_sym))
      result = glossaries.wait_for_import(current, max_wait_time: 5)
      expect(result.progress).to eq(1.0)
      expect(a_request(:post,
                       "#{base_url}/glossaries/imports/imp-1")).to have_been_made.at_least_once
    end
  end

  describe "#export" do
    it "returns CSV bytes" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:post, "#{base_url}/glossaries/#{glossary_id}/export").to_return(
        status: 200,
        body: "term,translation\nhello,ciao",
        headers: { "Content-Type" => "text/csv" }
      )
      result = glossaries.export(glossary_id, content_type: "csv/table-uni", source: "en")
      expect(result).to eq("term,translation\nhello,ciao")
    end
  end
end
