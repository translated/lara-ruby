# frozen_string_literal: true

module Lara
  class Memories
    def initialize(client)
      @client = client
      @polling_interval = 2
    end

    # @return [Array<Lara::Models::Memory>]
    def list
      (@client.get("/v2/memories") || []).map do |_h|
        Lara::Models::Memory.new(**_h.transform_keys(&:to_sym))
      end
    end

    # @return [Lara::Models::Memory]
    def create(name:, external_id: nil)
      payload = { name: name, external_id: external_id }.compact
      Lara::Models::Memory.new(**@client.post("/v2/memories",
                                              body: payload).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Memory,nil]
    def get(id)
      Lara::Models::Memory.new(**@client.get("/v2/memories/#{id}").transform_keys(&:to_sym))
    rescue Lara::LaraApiError => e
      return nil if e.status_code == 404

      raise
    end

    # @return [Lara::Models::Memory]
    def delete(id)
      Lara::Models::Memory.new(**@client.delete("/v2/memories/#{id}").transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Memory]
    def update(id, name:)
      Lara::Models::Memory.new(**@client.put("/v2/memories/#{id}",
                                             body: { name: name }).transform_keys(&:to_sym))
    end

    # @param ids [String,Array<String>]
    # @return [Lara::Models::Memory, Array<Lara::Models::Memory>, nil]
    def connect(ids)
      ids_array = ids.is_a?(Array) ? ids : [ids]
      results = @client.post("/v2/memories/connect", body: { ids: ids_array }) || []
      models = results.map { |_h| Lara::Models::Memory.new(**_h.transform_keys(&:to_sym)) }
      return models if ids.is_a?(Array)

      models.first
    end

    # @return [Lara::Models::MemoryImport]
    def add_translation(id_or_ids, source:, target:, sentence:, translation:, tuid: nil,
                        sentence_before: nil, sentence_after: nil, headers: nil)
      body = {
        source: source,
        target: target,
        sentence: sentence,
        translation: translation,
        tuid: tuid,
        sentence_before: sentence_before,
        sentence_after: sentence_after
      }.compact

      if id_or_ids.is_a?(Array)
        body[:ids] = id_or_ids
        Lara::Models::MemoryImport.new(**@client.put("/v2/memories/content",
                                                     body: body, headers: headers).transform_keys(&:to_sym))
      else
        Lara::Models::MemoryImport.new(**@client.put("/v2/memories/#{id_or_ids}/content",
                                                     body: body, headers: headers).transform_keys(&:to_sym))
      end
    end

    # @return [Lara::Models::MemoryImport]
    def delete_translation(id_or_ids, source:, target:, sentence:, translation:, tuid: nil,
                           sentence_before: nil, sentence_after: nil)
      body = {
        source: source,
        target: target,
        sentence: sentence,
        translation: translation,
        tuid: tuid,
        sentence_before: sentence_before,
        sentence_after: sentence_after
      }.compact

      if id_or_ids.is_a?(Array)
        body[:ids] = id_or_ids
        Lara::Models::MemoryImport.new(**@client.delete("/v2/memories/content",
                                                        body: body).transform_keys(&:to_sym))
      else
        Lara::Models::MemoryImport.new(**@client.delete("/v2/memories/#{id_or_ids}/content",
                                                        body: body).transform_keys(&:to_sym))
      end
    end

    # @return [Lara::Models::MemoryImport]
    def import_tmx(id, tmx_path)
      require "stringio"
      require "zlib"
      basename = File.basename(tmx_path)

      buffer = StringIO.new
      gz = Zlib::GzipWriter.new(buffer, 7, Zlib::DEFAULT_STRATEGY)
      File.open(tmx_path, "rb") { |_f| IO.copy_stream(_f, gz) }
      gz.finish
      buffer.rewind

      files = { "tmx" => Faraday::UploadIO.new(buffer, "application/gzip", "#{basename}.gz") }
      Lara::Models::MemoryImport.new(**@client.post("/v2/memories/#{id}/import",
                                                    body: { "compression" => "gzip" }, files: files).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::MemoryImport]
    def get_import_status(import_id)
      Lara::Models::MemoryImport.new(**@client.get("/v2/memories/imports/#{import_id}").transform_keys(&:to_sym))
    end

    # @return [Lara::Models::MemoryImport]
    def wait_for_import(memory_import, max_wait_time: 0)
      start = Time.now
      current = memory_import
      while current.progress && current.progress < 1.0
        if max_wait_time.to_f.positive? && (Time.now - start) > max_wait_time.to_f
          raise Timeout::Error
        end

        sleep @polling_interval
        current = get_import_status(current.id)
        yield current if block_given?
      end
      current
    end
  end
end
