# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Lara
  class S3Client
    def upload(url:, fields:, io:)
      payload_io = io.is_a?(String) ? File.open(io, "rb") : io

      begin
        filename = if io.is_a?(String)
                     File.basename(io)
                   else
                     io.respond_to?(:path) ? File.basename(io.path) : "upload.bin"
                   end

        conn = Faraday.new(url: url) do |f|
          f.request(:multipart)
          f.request(:url_encoded)
          f.adapter(Faraday.default_adapter)
        end

        file_part = Faraday::Multipart::FilePart.new(payload_io, "application/octet-stream",
                                                     filename)

        response = conn.post(nil) do |req|
          req.body = fields.transform_values(&:to_s).merge("file" => file_part)
        end

        raise Lara::LaraError, "S3 upload failed: HTTP #{response.status}" unless response.success?

        nil
      ensure
        payload_io.close if io.is_a?(String) && payload_io && !payload_io.closed?
      end
    rescue ArgumentError => e
      warn "[S3Client] upload ArgumentError: #{e.message}"
      raise
    rescue Faraday::Error => e
      warn "[S3Client] upload Faraday error: #{e.class} #{e.message}"
      raise Lara::LaraError, "S3 upload failed: #{e.message}"
    end

    def download(url:)
      conn = Faraday.new(url: url) { |f| f.adapter Faraday.default_adapter }
      response = conn.get
      raise Lara::LaraError, "S3 download failed: HTTP #{response.status}" unless response.success?

      response.body
    end
  end
end
