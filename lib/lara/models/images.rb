# frozen_string_literal: true

require_relative "base"
require_relative "text"

module Lara
  module Models
    module ImageTranslationModel
      OVERLAY         = "overlay"
      INPAINTING      = "inpainting"
      GENERATIVE      = "generative"
      GENERATIVE_FAST = "generative_fast"

      ALL = [OVERLAY, INPAINTING, GENERATIVE, GENERATIVE_FAST].freeze

      def self.valid?(value)
        ALL.include?(value)
      end
    end

    # Four corners, each an [x, y] pair of pixel coordinates.
    class ImageBBox < Base
      attr_reader :top_left, :top_right, :bottom_right, :bottom_left

      def initialize(top_left:, top_right:, bottom_right:, bottom_left:)
        super()
        @top_left = top_left
        @top_right = top_right
        @bottom_right = bottom_right
        @bottom_left = bottom_left
      end

      def self.from_hash(hash)
        new(top_left: hash["top_left"] || hash["topLeft"],
            top_right: hash["top_right"] || hash["topRight"],
            bottom_right: hash["bottom_right"] || hash["bottomRight"],
            bottom_left: hash["bottom_left"] || hash["bottomLeft"])
      end

      def to_render_hash
        { top_left: top_left, top_right: top_right, bottom_right: bottom_right, bottom_left: bottom_left }
      end
    end

    # Original text direction (ltr, rtl, or ttb) and colors.
    class ImageTextInfo < Base
      attr_reader :direction, :text_color, :background_color

      def initialize(direction:, text_color:, background_color:)
        super()
        @direction = direction
        @text_color = text_color
        @background_color = background_color
      end

      def self.from_hash(hash)
        new(direction: hash["direction"], text_color: hash["text_color"] || hash["textColor"],
            background_color: hash["background_color"] || hash["backgroundColor"])
      end

      def to_render_hash
        { direction: direction, text_color: text_color, background_color: background_color }
      end
    end

    class ImageParagraph < Base
      attr_reader :text, :translation, :adapted_to_matches, :glossaries_matches

      def initialize(text:, translation:, adapted_to_matches: nil, glossaries_matches: nil)
        super()
        @text = text
        @translation = translation
        @adapted_to_matches = adapted_to_matches
        @glossaries_matches = glossaries_matches
      end

      def to_render_hash
        { text: text, translation: translation }
      end
    end

    class ImageLayoutParagraph < ImageParagraph
      attr_reader :bbox, :lines_bboxes, :text_info, :alignment

      def initialize(text:, translation:, bbox:, lines_bboxes:, text_info:, alignment:,
                     adapted_to_matches: nil, glossaries_matches: nil)
        super(text: text, translation: translation, adapted_to_matches: adapted_to_matches,
              glossaries_matches: glossaries_matches)
        @bbox = bbox
        @lines_bboxes = lines_bboxes
        @text_info = text_info
        @alignment = alignment
      end

      def to_render_hash
        super.merge(bbox: bbox.to_render_hash, lines_bboxes: lines_bboxes.map(&:to_render_hash),
                    text_info: text_info.to_render_hash, alignment: alignment)
      end
    end

    class ImageTextResult < Base
      attr_reader :source_language, :adapted_to, :glossaries, :paragraphs

      def self.from_hash(hash)
        return nil unless hash.is_a?(Hash)

        paragraphs = (hash["paragraphs"] || []).map { |p| build_paragraph(p) }

        new(
          source_language: hash["source_language"] || hash["sourceLanguage"],
          adapted_to: hash["adapted_to"] || hash["adaptedTo"],
          glossaries: hash["glossaries"],
          paragraphs: paragraphs
        )
      end

      class << self
        private

        def build_paragraph(paragraph_hash)
          adapted_to_matches = convert_matches(
            paragraph_hash["adapted_to_matches"] || paragraph_hash["adaptedToMatches"], NGMemoryMatch
          )
          glossaries_matches = convert_matches(
            paragraph_hash["glossaries_matches"] || paragraph_hash["glossariesMatches"], NGGlossaryMatch
          )

          attributes = {
            text: paragraph_hash["text"],
            translation: paragraph_hash["translation"],
            adapted_to_matches: adapted_to_matches,
            glossaries_matches: glossaries_matches
          }
          bbox = paragraph_hash["bbox"]
          lines_bboxes = paragraph_hash["lines_bboxes"] || paragraph_hash["linesBboxes"]
          text_info = paragraph_hash["text_info"] || paragraph_hash["textInfo"]
          alignment = paragraph_hash["alignment"]
          if bbox && lines_bboxes && text_info && alignment
            ImageLayoutParagraph.new(**attributes, bbox: ImageBBox.from_hash(bbox),
                                     lines_bboxes: lines_bboxes.map { |box| ImageBBox.from_hash(box) },
                                     text_info: ImageTextInfo.from_hash(text_info), alignment: alignment)
          else
            ImageParagraph.new(**attributes)
          end
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
