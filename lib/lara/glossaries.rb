# frozen_string_literal: true

module Lara
  class Glossaries
    # Supported glossary file formats
    module FileFormat
      UNIDIRECTIONAL = "csv/table-uni"
      MULTIDIRECTIONAL = "csv/table-multi"

      # @return [Array<String>] All supported formats
      def self.all
        [UNIDIRECTIONAL, MULTIDIRECTIONAL]
      end

      # @param format [String] The format to validate
      # @return [Boolean] True if the format is supported
      def self.valid?(format)
        all.include?(format)
      end
    end
    def initialize(client)
      @client = client
      @polling_interval = 2
    end

    # @return [Array<Lara::Models::Glossary>]
    def list
      (@client.get("/v2/glossaries") || []).map do |_h|
        Lara::Models::Glossary.new(**_h.transform_keys(&:to_sym))
      end
    end

    # @return [Lara::Models::Glossary]
    def create(name:)
      Lara::Models::Glossary.new(**@client.post("/v2/glossaries",
                                                body: { name: name }).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Glossary,nil]
    def get(id)
      Lara::Models::Glossary.new(**@client.get("/v2/glossaries/#{id}").transform_keys(&:to_sym))
    rescue Lara::LaraApiError => e
      return nil if e.status_code == 404

      raise
    end

    # @return [Lara::Models::Glossary]
    def delete(id)
      Lara::Models::Glossary.new(**@client.delete("/v2/glossaries/#{id}").transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Glossary]
    def update(id, name:)
      Lara::Models::Glossary.new(**@client.put("/v2/glossaries/#{id}",
                                               body: { name: name }).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::GlossaryCounts]
    def counts(id)
      Lara::Models::GlossaryCounts.new(**@client.get("/v2/glossaries/#{id}/counts").transform_keys(&:to_sym))
    end

    # @param content_type [String] Either FileFormat::UNIDIRECTIONAL or FileFormat::MULTIDIRECTIONAL
    # @return [Lara::Models::GlossaryImport]
    def import_csv(id, csv_path, content_type: FileFormat::UNIDIRECTIONAL, gzip: true)
      unless FileFormat.valid?(content_type)
        raise ArgumentError, "Invalid content_type. Supported formats: #{FileFormat.all.join(', ')}"
      end

      require "stringio"
      require "zlib"
      basename = File.basename(csv_path)

      buffer = StringIO.new
      gz = Zlib::GzipWriter.new(buffer, 7, Zlib::DEFAULT_STRATEGY)
      File.open(csv_path, "rb") { |_f| IO.copy_stream(_f, gz) }
      gz.finish
      buffer.rewind

      body = { "compression" => "gzip" }
      body["content_type"] = content_type unless content_type == FileFormat::UNIDIRECTIONAL

      files = { "csv" => Faraday::UploadIO.new(buffer, "application/gzip", "#{basename}.gz") }
      Lara::Models::GlossaryImport.new(**@client.post("/v2/glossaries/#{id}/import",
                                                      body: body, files: files).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::GlossaryImport]
    def get_import_status(import_id)
      Lara::Models::GlossaryImport.new(**@client.get("/v2/glossaries/imports/#{import_id}").transform_keys(&:to_sym))
    end

    # @return [Lara::Models::GlossaryImport]
    def wait_for_import(glossary_import, max_wait_time: 0)
      start = Time.now
      current = glossary_import
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

    # Exports a csv file with the glossary content.
    # @param content_type [String] Either FileFormat::UNIDIRECTIONAL or FileFormat::MULTIDIRECTIONAL
    # @param source [String, nil] Optional source language
    # @return [String] bytes
    def export(id, content_type: FileFormat::UNIDIRECTIONAL, source: nil)
      unless FileFormat.valid?(content_type)
        raise ArgumentError, "Invalid content_type. Supported formats: #{FileFormat.all.join(', ')}"
      end

      @client.get("/v2/glossaries/#{id}/export",
                  params: { content_type: content_type, source: source }.compact)
    end

    # @param glossary_id [String] The glossary ID
    # @param terms [Array<Hash>] Array of term hashes with :language and :value keys
    # @param guid [String, nil] Optional unique identifier for multidirectional glossary units
    # @return [Lara::Models::GlossaryImport] The import operation
    def add_or_replace_entry(glossary_id, terms, guid: nil)
      body = { terms: terms }
      body[:guid] = guid if guid

      Lara::Models::GlossaryImport.new(**@client.put("/v2/glossaries/#{glossary_id}/content", body: body).transform_keys(&:to_sym))
    end

    # @param glossary_id [String] The glossary ID
    # @param term [Hash, nil] Optional term hash with :language and :value keys
    # @param guid [String, nil] Optional unique identifier for multidirectional glossary units
    # @return [Lara::Models::GlossaryImport] The import operation
    def delete_entry(glossary_id, term: nil, guid: nil)
      body = {}
      body[:guid] = guid if guid
      body[:term] = term if term

      Lara::Models::GlossaryImport.new(**@client.delete("/v2/glossaries/#{glossary_id}/content", body: body).transform_keys(&:to_sym))
    end
  end
end
