# frozen_string_literal: true

module Lara
  class Images
    def initialize(client)
      @client = client
    end

    # Translates an image and returns the translated image as binary data.
    # @param file_path [String] Path to the image file.
    # @param target [String] Target language code.
    # @param source [String, nil] Source language code (nil for auto-detection).
    # @param adapt_to [Array<String>, nil] Memory IDs for translation adaptation.
    # @param glossaries [Array<String>, nil] Glossary IDs to apply.
    # @param style [String, nil] Translation style ("faithful", "fluid", "creative").
    # @param model [String, nil] Image translation model. One of the +Lara::Models::ImageTranslationModel+ constants
    #   (+OVERLAY+, +INPAINTING+, +GENERATIVE+, +GENERATIVE_FAST+).
    # @param text_removal [String, nil] Deprecated. Use +model+ instead.
    # @param no_trace [Boolean] If true, disables request tracing.
    # @return [String] Binary image data of the translated image.
    def translate(file_path:, target:, source: nil, adapt_to: nil, glossaries: nil,
                  style: nil, model: nil, text_removal: nil, no_trace: false)
      image_upload = Faraday::Multipart::FilePart.new(file_path, mime_type_for(file_path))

      body = {
        source: source,
        target: target,
        adapt_to: adapt_to&.to_json,
        glossaries: glossaries&.to_json,
        style: style,
        model: model || text_removal
      }.compact

      headers = {}
      headers["X-No-Trace"] = "true" if no_trace

      @client.post("/v2/images/translate", body: body, files: { image: image_upload },
                                           headers: headers, raw_response: true)
    end

    # Extracts and translates text from an image.
    # @param file_path [String] Path to the image file.
    # @param target [String] Target language code.
    # @param source [String, nil] Source language code (nil for auto-detection).
    # @param adapt_to [Array<String>, nil] Memory IDs for translation adaptation.
    # @param glossaries [Array<String>, nil] Glossary IDs to apply.
    # @param style [String, nil] Translation style ("faithful", "fluid", "creative").
    # @param verbose [Boolean] If true, includes match details in the response.
    # @param no_trace [Boolean] If true, disables request tracing.
    # @return [Lara::Models::ImageTextResult]
    def translate_text(file_path:, target:, source: nil, adapt_to: nil, glossaries: nil,
                       style: nil, verbose: false, no_trace: false)
      image_upload = Faraday::Multipart::FilePart.new(file_path, mime_type_for(file_path))

      body = {
        source: source,
        target: target,
        adapt_to: adapt_to&.to_json,
        glossaries: glossaries&.to_json,
        style: style,
        verbose: verbose.to_s
      }.compact

      headers = {}
      headers["X-No-Trace"] = "true" if no_trace

      result = @client.post("/v2/images/translate-text", body: body, files: { image: image_upload },
                                                         headers: headers)
      Lara::Models::ImageTextResult.from_hash(result)
    end

    private

    def mime_type_for(file_path)
      require "mime/types"
      ext = File.extname(file_path).downcase
      MIME::Types.of(ext).first&.content_type || "application/octet-stream"
    end
  end
end
