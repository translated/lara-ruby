# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    class TextBlock < Base
      attr_reader :text, :translatable

      def initialize(text:, translatable: true)
        super()
        @text = text
        @translatable = !!translatable
      end
    end

    class NGMemoryMatch < Base
      attr_reader :memory, :tuid, :language, :sentence, :translation

      def initialize(memory:, language:, sentence:, translation:, tuid: nil)
        super()
        @memory = memory
        @tuid = tuid
        @language = language
        @sentence = sentence
        @translation = translation
      end
    end

    class NGGlossaryMatch < Base
      attr_reader :glossary, :language, :term, :translation

      def initialize(glossary:, language:, term:, translation:)
        super()
        @glossary = glossary
        @language = language
        @term = term
        @translation = translation
      end
    end

    class DetectedProfanity < Base
      attr_reader :text, :start_char_index, :end_char_index, :score

      def initialize(text:, start_char_index:, end_char_index:, score:)
        super()
        @text = text
        @start_char_index = start_char_index
        @end_char_index = end_char_index
        @score = score
      end
    end

    class ProfanityDetectResult < Base
      attr_reader :masked_text, :profanities

      def initialize(masked_text:, profanities: [])
        super()
        @masked_text = masked_text
        @profanities = profanities.map do |p|
          DetectedProfanity.new(
            text: p["text"] || p[:text],
            start_char_index: p["start_char_index"] || p[:start_char_index],
            end_char_index: p["end_char_index"] || p[:end_char_index],
            score: p["score"] || p[:score]
          )
        end
      end
    end

    class DetectPrediction < Base
      attr_reader :language, :confidence

      def initialize(language:, confidence:)
        super()
        @language = language
        @confidence = confidence
      end
    end

    class DetectResult < Base
      attr_reader :language, :content_type, :predictions

      def initialize(language:, content_type:, predictions: [])
        super()
        @language = language
        @content_type = content_type
        @predictions = predictions.map { |p| DetectPrediction.new(**p.transform_keys(&:to_sym)) }
      end
    end

    class TextResult < Base
      attr_reader :content_type, :source_language, :translation,
                  :adapted_to, :glossaries,
                  :adapted_to_matches, :glossaries_matches,
                  :profanities

      def self.from_hash(hash)
        return nil unless hash.is_a?(Hash)

        translation = hash["translation"]
        if translation.is_a?(Array) && translation.is_a?(Array) && !translation.all?(String)
          translation = translation.map do |e|
            TextBlock.new(text: e["text"],
                          translatable: e["translatable"])
          end
        end

        adapted_to_matches = convert_matches(hash["adapted_to_matches"], NGMemoryMatch)
        glossaries_matches = convert_matches(hash["glossaries_matches"], NGGlossaryMatch)
        profanities = convert_profanities(hash["profanities"])

        new(
          content_type: hash["content_type"],
          source_language: hash["source_language"],
          translation: translation,
          adapted_to: hash["adapted_to"],
          glossaries: hash["glossaries"],
          adapted_to_matches: adapted_to_matches,
          glossaries_matches: glossaries_matches,
          profanities: profanities
        )
      end

      def initialize(content_type:, source_language:, translation:, adapted_to: nil, glossaries: nil,
                     adapted_to_matches: nil, glossaries_matches: nil, profanities: nil)
        super()
        @content_type = content_type
        @source_language = source_language
        @translation = translation
        @adapted_to = adapted_to
        @glossaries = glossaries
        @adapted_to_matches = adapted_to_matches
        @glossaries_matches = glossaries_matches
        @profanities = profanities
      end

      class << self
        private

        def convert_matches(value, klass)
          return nil if value.nil?

          return unless value.is_a?(Array)

          if value.empty?
            []
          elsif value.first.is_a?(Array)
            value.map { |arr| arr.map { |h| build_match(klass, h) } }
          else
            value.map { |h| build_match(klass, h) }
          end
        end

        def convert_profanities(value)
          return nil if value.nil?

          if value.is_a?(Hash)
            ProfanityDetectResult.new(
              masked_text: value["masked_text"],
              profanities: value["profanities"] || []
            )
          elsif value.is_a?(Array)
            value.map do |v|
              next nil if v.nil?

              ProfanityDetectResult.new(
                masked_text: v["masked_text"],
                profanities: v["profanities"] || []
              )
            end
          end
        end

        def build_match(klass, h)
          case klass.name.split("::").last
          when "NGMemoryMatch"
            NGMemoryMatch.new(
              memory: h["memory"],
              tuid: h["tuid"],
              language: h["language"],
              sentence: h["sentence"],
              translation: h["translation"]
            )
          when "NGGlossaryMatch"
            NGGlossaryMatch.new(
              glossary: h["glossary"],
              language: h["language"],
              term: h["term"],
              translation: h["translation"]
            )
          end
        end
      end
    end
  end
end
