# frozen_string_literal: true

require "tempfile"
require "zlib"
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
    it "returns empty array when no glossaries" do
      stub_get("/v2/glossaries", [])
      expect(glossaries.list).to eq([])
    end

    it "returns array of Glossary" do
      stub_get("/v2/glossaries", [glossary_content])
      list = glossaries.list
      expect(list.size).to eq(1)
      expect(list.first).to be_a(Lara::Models::Glossary)
      expect(list.first.id).to eq("gls_1Bc2De3Fg4Hi5Jk6Lm7No")
      expect(list.first.is_personal).to be(true)
    end
  end

  describe "#create" do
    it "creates with name" do
      stub_post("/v2/glossaries", glossary_content)
      g = glossaries.create(name: "Test Glossary")
      expect(g).to be_a(Lara::Models::Glossary)
      expect(g.name).to eq("Test Glossary")
    end
  end

  describe "#get" do
    it "returns Glossary when found" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_get("/v2/glossaries/#{glossary_id}", glossary_content)
      g = glossaries.get(glossary_id)
      expect(g).to be_a(Lara::Models::Glossary)
      expect(g.id).to eq(glossary_id)
    end

    it "returns nil on 404" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:get, "#{base_url}/v2/glossaries/#{glossary_id}").to_return(
        status: 404,
        body: { "type" => "NotFound", "message" => "Not found" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(glossaries.get(glossary_id)).to be_nil
    end
  end

  describe "#delete" do
    it "returns Glossary" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_delete("/v2/glossaries/#{glossary_id}", glossary_content)
      g = glossaries.delete(glossary_id)
      expect(g).to be_a(Lara::Models::Glossary)
    end
  end

  describe "#update" do
    it "returns updated Glossary" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_put("/v2/glossaries/#{glossary_id}", glossary_content.merge("name" => "Updated"))
      g = glossaries.update(glossary_id, name: "Updated")
      expect(g.name).to eq("Updated")
    end
  end

  describe "#counts" do
    it "returns GlossaryCounts" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_get("/v2/glossaries/#{glossary_id}/counts", "unidirectional" => 10,
                                                       "multidirectional" => 5)
      c = glossaries.counts(glossary_id)
      expect(c).to be_a(Lara::Models::GlossaryCounts)
      expect(c.unidirectional).to eq(10)
      expect(c.multidirectional).to eq(5)
    end
  end

  describe "#import_csv" do
    it "uploads uncompressed csv by default and returns GlossaryImport" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0 }
      stub_request(:post, "#{base_url}/v2/glossaries/#{glossary_id}/import").to_return(
        status: 200,
        body: import_content.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["test", ".csv"]) do |f|
        f.write("term,translation\nhello,ciao")
        f.rewind
        imp = glossaries.import_csv(glossary_id, f.path)
        expect(imp).to be_a(Lara::Models::GlossaryImport)
        expect(imp.id).to eq("imp-1")
        expect(WebMock).to(have_requested(:post,
                                          "#{base_url}/v2/glossaries/#{glossary_id}/import").with do |req|
          req.body.include?("term,translation") && !req.body.include?("compression")
        end)
      end
    end

    it "uploads already gzipped csv unchanged when gzip is true" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0 }
      stub_request(:post, "#{base_url}/v2/glossaries/#{glossary_id}/import").to_return(
        status: 200,
        body: import_content.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["test", ".csv"]) do |f|
        compressed = Zlib.gzip("term,translation\nhello,ciao")
        f.binmode
        f.write(compressed)
        f.rewind
        imp = glossaries.import_csv(glossary_id, f.path, gzip: true)
        expect(imp.id).to eq("imp-1")
        expect(WebMock).to(have_requested(:post,
                                          "#{base_url}/v2/glossaries/#{glossary_id}/import").with do |req|
          req.body.include?("compression") && req.body.b.include?(compressed)
        end)
      end
    end

    it "sends callback_url when provided" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      callback_url = "https://example.com/callback"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0 }
      stub_request(:post, "#{base_url}/v2/glossaries/#{glossary_id}/import").to_return(
        status: 200,
        body: import_content.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["test", ".csv"]) do |f|
        f.write("term,translation\nhello,ciao")
        f.rewind
        imp = glossaries.import_csv(glossary_id, f.path, callback_url: callback_url)
        expect(imp).to be_a(Lara::Models::GlossaryImport)
        expect(WebMock).to(have_requested(:post,
                                          "#{base_url}/v2/glossaries/#{glossary_id}/import").with do |req|
          req.body.include?("callback_url") && req.body.include?(callback_url)
        end)
      end
    end
  end

  describe "#get_import_status" do
    it "returns GlossaryImport" do
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0.5 }
      stub_get("/v2/glossaries/imports/imp-1", import_content)
      imp = glossaries.get_import_status("imp-1")
      expect(imp.progress).to eq(0.5)
    end
  end

  describe "#wait_for_import" do
    it "polls until progress is 1.0" do
      import_initial = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 0.5 }
      import_done = { "id" => "imp-1", "channel" => "main", "size" => 50, "progress" => 1.0 }
      stub_request(:get, "#{base_url}/v2/glossaries/imports/imp-1").to_return(
        {
          status: 200,
          body: import_initial.to_json,
          headers: { "Content-Type" => "application/json" }
        },
        {
          status: 200,
          body: import_done.to_json,
          headers: { "Content-Type" => "application/json" }
        }
      )
      glossaries.instance_variable_set(:@polling_interval, 0)
      current = Lara::Models::GlossaryImport.new(**import_initial.transform_keys(&:to_sym))
      result = glossaries.wait_for_import(current, max_wait_time: 5)
      expect(result.progress).to eq(1.0)
      expect(a_request(:get,
                       "#{base_url}/v2/glossaries/imports/imp-1")).to have_been_made.at_least_once
    end
  end

  describe "#export_async" do
    it "calls get with query params and returns GlossaryExport" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      export_content = { "job_id" => "export-1" }
      stub_request(:get, "#{base_url}/v2/glossaries/#{glossary_id}/export/async")
        .with(query: {
                "callback_url" => "https://example.com/cb",
                "content_type" => "csv/table-uni",
                "source" => "en-US"
              })
        .to_return(
          status: 200,
          body: export_content.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      export_job = glossaries.export_async(glossary_id, callback_url: "https://example.com/cb",
                                                        content_type: "csv/table-uni", source: "en-US")
      expect(export_job).to be_a(Lara::Models::GlossaryExport)
      expect(export_job.job_id).to eq("export-1")
    end

    it "omits source for multidirectional export" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      export_content = { "job_id" => "export-multi" }
      stub_request(:get, "#{base_url}/v2/glossaries/#{glossary_id}/export/async")
        .with(query: {
                "callback_url" => "https://example.com/cb",
                "content_type" => "csv/table-multi"
              })
        .to_return(
          status: 200,
          body: export_content.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      export_job = glossaries.export_async(glossary_id, callback_url: "https://example.com/cb",
                                                        content_type: "csv/table-multi")
      expect(export_job.job_id).to eq("export-multi")
    end
  end

  describe "#export" do
    it "returns CSV bytes" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      stub_request(:get, "#{base_url}/v2/glossaries/#{glossary_id}/export")
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: "term,translation\nhello,ciao",
          headers: { "Content-Type" => "text/csv" }
        )
      result = glossaries.export(glossary_id, content_type: "csv/table-uni", source: "en")
      expect(result).to eq("term,translation\nhello,ciao")
    end
  end

  describe "#add_or_replace_entry" do
    it "puts terms and returns GlossaryImport" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      import_content = { "id" => "imp-2", "channel" => "main", "size" => 1, "progress" => 1.0 }
      stub_put("/v2/glossaries/#{glossary_id}/content", import_content)
      terms = [{ language: "en", value: "hello" }, { language: "it", value: "ciao" }]
      imp = glossaries.add_or_replace_entry(glossary_id, terms, guid: "guid-1")
      expect(imp).to be_a(Lara::Models::GlossaryImport)
      expect(imp.id).to eq("imp-2")
    end
  end

  describe "#delete_entry" do
    it "deletes entry and returns GlossaryImport" do
      glossary_id = "gls_1Bc2De3Fg4Hi5Jk6Lm7No"
      import_content = { "id" => "imp-3", "channel" => "main", "size" => 0, "progress" => 1.0 }
      stub_delete("/v2/glossaries/#{glossary_id}/content", import_content)
      imp = glossaries.delete_entry(glossary_id, term: { language: "en", value: "hello" },
                                                 guid: "guid-1")
      expect(imp).to be_a(Lara::Models::GlossaryImport)
      expect(imp.id).to eq("imp-3")
    end
  end

  it_behaves_like "a shareable resource" do
    let(:resource_api) { glossaries }
    let(:resource_path) { "/v2/glossaries" }
    let(:resource_id) { "gls_1Bc2De3Fg4Hi5Jk6Lm7No" }
    let(:resource_content) { glossary_content }
    let(:resource_key) { :glossary }
    let(:resource_model) { Lara::Models::Glossary }
    let(:shares_model) { Lara::Models::GlossaryShares }
  end
end
