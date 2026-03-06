# frozen_string_literal: true

require_relative "base"
require_relative "text"

module Lara
  module Models
    class ImageParagraph < Base
      attr_reader :text, :translation, :adapted_to_matches, :glossaries_matches

      def initialize(text:, translation:, adapted_to_matches: nil, glossaries_matches: nil)
        super()
        @text = text
        @translation = translation
        @adapted_to_matches = adapted_to_matches
        @glossaries_matches = glossaries_matches
      end
    end

    class ImageTextResult < Base
      attr_reader :source_language, :adapted_to, :glossaries, :paragraphs

      def self.from_hash(hash)
        return nil unless hash.is_a?(Hash)

        paragraphs = (hash["paragraphs"] || []).map { |p| build_paragraph(p) }

        new(
          source_language: hash["sourceLanguage"],
          adapted_to: hash["adaptedTo"],
          glossaries: hash["glossaries"],
          paragraphs: paragraphs
        )
      end

      class << self
        private

        def build_paragraph(paragraph_hash)
          adapted_to_matches = convert_matches(paragraph_hash["adaptedToMatches"], NGMemoryMatch)
          glossaries_matches = convert_matches(paragraph_hash["glossariesMatches"], NGGlossaryMatch)

          ImageParagraph.new(
            text: paragraph_hash["text"],
            translation: paragraph_hash["translation"],
            adapted_to_matches: adapted_to_matches,
            glossaries_matches: glossaries_matches
          )
        end

        def convert_matches(value, klass)
          return nil if value.nil?
          return unless value.is_a?(Array)

          value.map { |h| build_match(klass, h) }
        end

        def build_match(klass, hash)
          case klass.name.split("::").last
          when "NGMemoryMatch"
            NGMemoryMatch.new(
              memory: hash["memory"],
              tuid: hash["tuid"],
              language: hash["language"],
              sentence: hash["sentence"],
              translation: hash["translation"]
            )
          when "NGGlossaryMatch"
            NGGlossaryMatch.new(
              glossary: hash["glossary"],
              language: hash["language"],
              term: hash["term"],
              translation: hash["translation"]
            )
          end
        end
      end

      def initialize(source_language:, paragraphs:, adapted_to: nil, glossaries: nil)
        super()
        @source_language = source_language
        @adapted_to = adapted_to
        @glossaries = glossaries
        @paragraphs = paragraphs
      end
    end
  end
end
