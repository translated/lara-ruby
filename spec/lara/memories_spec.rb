# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::Memories do
  let(:base_url) { Lara::Client::DEFAULT_BASE_URL }
  let(:credentials) { Lara::Credentials.new("test-id", "test-secret") }
  let(:client) { Lara::Client.new(credentials, base_url: base_url) }
  let(:memories) { described_class.new(client) }

  def memory_content
    api_content_fixture("memory")
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
    it "returns empty array when no memories" do
      stub_get("/memories", [])
      expect(memories.list).to eq([])
    end

    it "returns array of Memory" do
      stub_get("/memories", [memory_content])
      list = memories.list
      expect(list.size).to eq(1)
      expect(list.first).to be_a(Lara::Models::Memory)
      expect(list.first.id).to eq("mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn")
      expect(list.first.name).to eq("Test Memory")
    end
  end

  describe "#create" do
    it "creates with name and optional external_id" do
      stub_post("/memories", memory_content)
      m = memories.create(name: "Test Memory", external_id: "ext_3De4Fg5Hi6Jk7Lm8No9Pq")
      expect(m).to be_a(Lara::Models::Memory)
      expect(m.name).to eq("Test Memory")
    end
  end

  describe "#get" do
    it "returns Memory when found" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_get("/memories/#{memory_id}", memory_content)
      m = memories.get(memory_id)
      expect(m).to be_a(Lara::Models::Memory)
      expect(m.id).to eq(memory_id)
    end

    it "returns nil on 404" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_request(:post, "#{base_url}/memories/#{memory_id}").to_return(
        status: 404,
        body: { "error" => { "type" => "NotFound", "message" => "Not found" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(memories.get(memory_id)).to be_nil
    end
  end

  describe "#delete" do
    it "returns Memory" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_delete("/memories/#{memory_id}", memory_content)
      m = memories.delete(memory_id)
      expect(m).to be_a(Lara::Models::Memory)
    end
  end

  describe "#update" do
    it "returns updated Memory" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      stub_put("/memories/#{memory_id}", memory_content.merge("name" => "Updated"))
      m = memories.update(memory_id, name: "Updated")
      expect(m.name).to eq("Updated")
    end
  end

  describe "#connect" do
    it "returns single Memory when single external id" do
      stub_post("/memories/connect", [memory_content])
      m = memories.connect("ext_3De4Fg5Hi6Jk7Lm8No9Pq")
      expect(m).to be_a(Lara::Models::Memory)
    end

    it "returns array when array of external ids" do
      memory2 = memory_content.merge("id" => "mem_1Bc2De3Fg4Hi5Jk6Lm7No")
      stub_post("/memories/connect", [memory_content, memory2])
      list = memories.connect(%w[ext_3De4Fg5Hi6Jk7Lm8No9Pq ext_5Fg6Hi7Jk8Lm9No0Pr1Qs])
      expect(list).to be_an(Array)
      expect(list.size).to eq(2)
    end
  end

  describe "#add_translation" do
    it "calls put for single id" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 10, "progress" => 1.0 }
      stub_put("/memories/#{memory_id}/content", import_content)
      imp = memories.add_translation(memory_id, source: "en", target: "it", sentence: "Hi",
                                                translation: "Ciao")
      expect(imp).to be_a(Lara::Models::MemoryImport)
      expect(imp.id).to eq("imp-1")
    end

    it "calls put /memories/content with ids for array" do
      memory_ids = %w[mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn mem_1Bc2De3Fg4Hi5Jk6Lm7No]
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 10, "progress" => 1.0 }
      stub_put("/memories/content", import_content)
      memories.add_translation(memory_ids, source: "en", target: "it", sentence: "Hi",
                                                translation: "Ciao")
      expect(WebMock).to(have_requested(:post, "#{base_url}/memories/content").with do |req|
        body = JSON.parse(req.body)
        body["ids"] == memory_ids
      end)
    end
  end

  describe "#delete_translation" do
    it "calls delete for single id" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 0, "progress" => 1.0 }
      stub_request(:post, "#{base_url}/memories/#{memory_id}/content").to_return(
        status: 200,
        body: { "content" => import_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      imp = memories.delete_translation(memory_id, source: "en", target: "it", sentence: "Hi",
                                                   translation: "Ciao")
      expect(imp).to be_a(Lara::Models::MemoryImport)
    end
  end

  describe "#import_tmx" do
    it "uploads gzipped tmx and returns MemoryImport" do
      memory_id = "mem_0Ab1Cd2Ef3Gh4Ij5Kl6Mn"
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 100, "progress" => 0 }
      stub_request(:post, "#{base_url}/memories/#{memory_id}/import").to_return(
        status: 200,
        body: { "content" => import_content }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      Tempfile.create(["test", ".tmx"]) do |f|
        f.write("<tmx></tmx>")
        f.rewind
        imp = memories.import_tmx(memory_id, f.path)
        expect(imp).to be_a(Lara::Models::MemoryImport)
        expect(imp.id).to eq("imp-1")
      end
    end
  end

  describe "#get_import_status" do
    it "returns MemoryImport" do
      import_content = { "id" => "imp-1", "channel" => "main", "size" => 100, "progress" => 0.5 }
      stub_get("/memories/imports/imp-1", import_content)
      imp = memories.get_import_status("imp-1")
      expect(imp.progress).to eq(0.5)
    end
  end

  describe "#wait_for_import" do
    it "polls until progress is 1.0 and returns final import" do
      import_in_progress = { "id" => "imp-1", "channel" => "main", "size" => 100,
                             "progress" => 0.5 }
      import_done = { "id" => "imp-1", "channel" => "main", "size" => 100, "progress" => 1.0 }
      stub_request(:post, "#{base_url}/memories/imports/imp-1")
        .to_return(
          { status: 200, body: { "content" => import_in_progress }.to_json,
            headers: { "Content-Type" => "application/json" } },
          { status: 200, body: { "content" => import_done }.to_json,
            headers: { "Content-Type" => "application/json" } }
        )
      memories.instance_variable_set(:@polling_interval, 0)
      current = Lara::Models::MemoryImport.new(**import_in_progress.transform_keys(&:to_sym))
      result = memories.wait_for_import(current, max_wait_time: 5)
      expect(result.progress).to eq(1.0)
    end

    it "yields block with current import when given" do
      import_in_progress = { "id" => "imp-1", "channel" => "main", "size" => 100,
                             "progress" => 0.5 }
      import_done = { "id" => "imp-1", "channel" => "main", "size" => 100, "progress" => 1.0 }
      stub_request(:post, "#{base_url}/memories/imports/imp-1")
        .to_return(
          { status: 200, body: { "content" => import_in_progress }.to_json,
            headers: { "Content-Type" => "application/json" } },
          { status: 200, body: { "content" => import_done }.to_json,
            headers: { "Content-Type" => "application/json" } }
        )
      memories.instance_variable_set(:@polling_interval, 0)
      current = Lara::Models::MemoryImport.new(**import_in_progress.transform_keys(&:to_sym))
      yielded = nil
      memories.wait_for_import(current, max_wait_time: 5) { |c| yielded = c }
      expect(yielded).to be_a(Lara::Models::MemoryImport)
      expect(yielded.progress).to eq(1.0)
    end
  end
end
