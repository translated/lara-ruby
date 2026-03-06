# frozen_string_literal: true

module Lara
  class Documents
    ALLOWED_DOCUMENT_PARAMS = %i[
      id
      status
      target
      filename
      source
      created_at
      updated_at
      options
      translated_chars
      total_chars
      error_reason
    ].freeze

    def initialize(client, s3_client = S3Client.new)
      @client = client
      @s3 = s3_client
      @polling_interval = 2
    end

    # Uploads a file to S3
    # @return [Lara::Models::Document]
    def upload(file_path:, filename:, target:, source: nil, adapt_to: nil, glossaries: nil,
               no_trace: false, style: nil, password: nil, extraction_params: nil)
      response_data = @client.get("/v2/documents/upload-url", params: { filename: filename })
      url = response_data["url"]
      fields = response_data["fields"]

      @s3.upload(url: url, fields: fields, io: file_path)

      body = {
        s3key: fields["key"],
        target: target,
        source: source,
        adapt_to: adapt_to,
        glossaries: glossaries,
        style: style,
        password: password,
        extraction_params: extraction_params&.to_h
      }.compact

      headers = {}
      headers["X-No-Trace"] = "true" if no_trace

      response = @client.post("/v2/documents", body: body, headers: headers)
      response_params = response.transform_keys(&:to_sym)
      Lara::Models::Document.new(**filter_document_params(response_params))
    end

    # Fetch document status
    # @return [Lara::Models::Document]
    def status(id)
      response = @client.get("/v2/documents/#{id}")
      response_params = response.transform_keys(&:to_sym)
      Lara::Models::Document.new(**filter_document_params(response_params))
    end

    # Download translated document bytes
    # @return [String] bytes
    def download(id, output_format: nil)
      params = {}
      params[:output_format] = output_format if output_format
      url = @client.get("/v2/documents/#{id}/download-url", params: params)["url"]
      @s3.download(url: url)
    end

    # Translates a document end-to-end
    # @return [String] translated file bytes
    def translate(file_path:, filename:, target:, source: nil, adapt_to: nil, glossaries: nil, output_format: nil,
                  no_trace: false, style: nil, password: nil, extraction_params: nil)
      document = upload(file_path: file_path, filename: filename, target: target, source: source,
                        adapt_to: adapt_to, glossaries: glossaries, no_trace: no_trace, style: style, password: password,
                        extraction_params: extraction_params)

      max_wait_time = 60 * 15 # 15 minutes
      start = Time.now

      loop do |_|
        current = status(document.id)

        case current.status
        when Lara::Models::DocumentStatus::TRANSLATED
          return download(current.id, output_format: output_format)
        when Lara::Models::DocumentStatus::ERROR
          raise Lara::LaraApiError.new(500, "DocumentError",
                                       current.error_reason || "Unknown error")
        end

        raise Timeout::Error if Time.now - start > max_wait_time

        sleep @polling_interval
      end
    end

    private

    def filter_document_params(params)
      params.slice(*ALLOWED_DOCUMENT_PARAMS)
    end
  end
end
