# frozen_string_literal: true

require_relative "client"

module Lara
  class Translator
    # @param credentials [Lara::Credentials,nil]
    # @param auth_token [Lara::AuthToken,nil]
    # @param access_key_id [String,nil]
    # @param access_key_secret [String,nil]
    # @param base_url [String,nil]
    # @param connection_timeout [Integer,nil]
    # @param read_timeout [Integer,nil]
    def initialize(credentials: nil, auth_token: nil, access_key_id: nil, access_key_secret: nil,
                   base_url: nil, connection_timeout: nil, read_timeout: nil)
      auth_method = if auth_token
                      auth_token
                    elsif credentials
                      credentials
                    elsif access_key_id && access_key_secret
                      Credentials.new(access_key_id, access_key_secret)
                    else
                      raise ArgumentError,
                            "either credentials, auth_token, or access_key_id and access_key_secret must be provided"
                    end

      @client = Client.new(auth_method, base_url: base_url,
                                        connection_timeout: connection_timeout, read_timeout: read_timeout)
      @memories = Memories.new(@client)
      @glossaries = Glossaries.new(@client)
      @styleguides = Styleguides.new(@client)
      @documents = Documents.new(@client)
      @images = Images.new(@client)
      @audio = AudioTranslator.new(@client)
    end

    attr_reader :client, :memories, :glossaries, :styleguides, :documents, :images, :audio

    # Translates text with optional tuning parameters.
    # @param text [String, Array<String>, Array<Lara::Models::TextBlock>]
    # @param source [String,nil]
    # @param source_hint [String,nil]
    # @param target [String]
    # @param adapt_to [Array<String>,nil]
    # @param glossaries [Array<String>,nil]
    # @param instructions [Array<String>,nil]
    # @param content_type [String,nil]
    # @param multiline [Boolean]
    # @param timeout_ms [Integer,nil]
    # @param priority [String,nil]
    # @param use_cache [String,Boolean,nil]
    # @param cache_ttl_s [Integer,nil]
    # @param no_trace [Boolean]
    # @param verbose [Boolean]
    # @param style [String,nil]
    # @param reasoning [Boolean] When true with a block, yields partial results during reasoning
    # @param headers [Hash,nil]
    # @param metadata [String, Hash, nil]
    # @param profanities_detect [String,nil] One of "target", "source_target"
    # @param profanities_handling [String,nil] One of "detect", "avoid", "hide" (default: "hide" when profanities_detect is set)
    # @yield [Lara::Models::TextResult] Partial translation result (only when reasoning is true)
    # @return [Lara::Models::TextResult] Final translation result
    def translate(text, target:, source: nil, source_hint: nil, adapt_to: nil, glossaries: nil,
                  instructions: nil, content_type: nil, multiline: true, timeout_ms: nil,
                  priority: nil, use_cache: nil, cache_ttl_s: nil, no_trace: false, verbose: false,
                  style: nil, reasoning: false, headers: nil, metadata: nil,
                  profanities_detect: nil, profanities_handling: nil,
                  styleguide_id: nil, styleguide_reasoning: nil,
                  styleguide_explanation_language: nil, &callback)
      q = normalize_text_input(text)

      use_cache_value = case use_cache
                        when true then "yes"
                        when false then "no"
                        else use_cache
                        end

      body = {
        q: q,
        source: source,
        target: target,
        source_hint: source_hint,
        content_type: content_type,
        multiline: multiline,
        adapt_to: adapt_to,
        glossaries: glossaries,
        instructions: instructions,
        timeout: timeout_ms,
        priority: priority,
        use_cache: use_cache_value,
        cache_ttl: cache_ttl_s,
        verbose: verbose,
        style: style,
        reasoning: reasoning,
        metadata: metadata,
        profanities_detect: profanities_detect,
        profanities_handling: profanities_handling,
        styleguide_id: styleguide_id,
        styleguide_reasoning: styleguide_reasoning,
        styleguide_explanation_language: styleguide_explanation_language
      }.compact

      request_headers = {}
      request_headers.merge!(headers) if headers.is_a?(Hash)
      request_headers["X-No-Trace"] = "true" if no_trace

      stream_callback = if callback && reasoning
                          ->(partial) { callback.call(Lara::Models::TextResult.from_hash(partial)) }
                        end

      result = @client.post("/v2/translate", body: body, headers: request_headers, &stream_callback)
      Lara::Models::TextResult.from_hash(result) if result
    end

    # Detects the language of the given text.
    # @param text [String, Array<String>] Text to detect language for
    # @param hint [String, nil] Language hint
    # @param passlist [Array<String>, nil] List of allowed languages
    # @return [Lara::Models::DetectResult]
    def detect(text, hint: nil, passlist: nil)
      body = { q: text }
      body[:hint] = hint if hint
      body[:passlist] = passlist if passlist&.any?
      body = body.compact

      result = @client.post("/v2/detect/language", body: body)
      Lara::Models::DetectResult.new(
        language: result["language"],
        content_type: result["content_type"],
        predictions: result["predictions"] || []
      )
    end

    VALID_CONTENT_TYPES = %w[text/plain text/html text/xml application/xliff+xml].freeze

    # Detects profanities in the given text.
    # @param text [String] Text to check for profanities
    # @param language [String] Language code (e.g. "en")
    # @param content_type [String] One of "text/plain", "text/html", "text/xml", "application/xliff+xml"
    # @return [Lara::Models::ProfanityDetectResult]
    def detect_profanities(text, language:, content_type: "text/plain")
      unless VALID_CONTENT_TYPES.include?(content_type)
        raise ArgumentError, "Invalid content_type '#{content_type}'. Must be one of: #{VALID_CONTENT_TYPES.join(', ')}"
      end

      body = { text: text, language: language, content_type: content_type }
      result = @client.post("/v2/detect/profanities", body: body)
      Lara::Models::ProfanityDetectResult.new(
        masked_text: result["masked_text"],
        profanities: result["profanities"] || [],
        error: result["error"]
      )
    end

    # Estimates translation quality for a sentence pair (or batch of pairs).
    # @param source [String]
    # @param target [String]
    # @param sentence [String, Array<String>]
    # @param translation [String, Array<String>]
    # @return [Lara::Models::QualityEstimationResult, Array<Lara::Models::QualityEstimationResult>]
    def quality_estimation(source:, target:, sentence:, translation:)
      body = {
        source: source,
        target: target,
        sentence: sentence,
        translation: translation
      }

      result = @client.post("/v2/detect/quality-estimation", body: body)
      if result.is_a?(Array)
        result.map { |r| Lara::Models::QualityEstimationResult.new(score: r["score"] || r[:score]) }
      else
        Lara::Models::QualityEstimationResult.new(score: result["score"] || result[:score])
      end
    end

    # Lists supported language codes.
    def get_languages
      @client.get("/v2/languages")
    end

    private

    def normalize_text_input(text)
      case text
      when String
        text
      when Array
        if text.all?(String)
          text
        elsif text.all?(Lara::Models::TextBlock)
          text.map { |tb| { text: tb.text, translatable: tb.translatable } }
        else
          raise ArgumentError, "text must be an iterable of strings or TextBlock objects"
        end
      else
        raise ArgumentError, "text must be a string or an iterable"
      end
    end
  end
end
