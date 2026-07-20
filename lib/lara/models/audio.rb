# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    module VoiceGender
      MALE = "male"
      FEMALE = "female"
      ALL = [MALE, FEMALE].freeze

      def self.valid?(value)
        ALL.include?(value)
      end
    end

    module AudioStatus
      INITIALIZED = "initialized"
      ANALYZING   = "analyzing"
      PAUSED      = "paused"
      READY       = "ready"
      TRANSLATING = "translating"
      TRANSLATED  = "translated"
      ERROR       = "error"

      ALL = [
        INITIALIZED, ANALYZING, PAUSED, READY, TRANSLATING, TRANSLATED, ERROR
      ].freeze

      def self.valid?(value)
        ALL.include?(value)
      end
    end

    class Audio < Base
      attr_reader :id, :status, :source, :target, :filename, :created_at, :updated_at,
                  :options, :translated_seconds, :total_seconds, :error_reason

      def initialize(id:, status:, filename:, target: nil, source: nil, created_at: nil, updated_at: nil,
                     options: nil, translated_seconds: nil, total_seconds: nil, error_reason: nil)
        super()
        @id = id
        @status = status
        @source = source
        @target = target
        @filename = filename
        @created_at = Base.parse_time(created_at)
        @updated_at = Base.parse_time(updated_at)
        @options = options
        @translated_seconds = translated_seconds&.to_f
        @total_seconds = total_seconds&.to_f
        @error_reason = error_reason
      end
    end

    # Audio text segment for transcript results
    class AudioTextSegment < Base
      attr_reader :id, :start, :text, :translation

      # JSON field is "end"; expose as #end to match the wire contract / other SDKs.
      attr_reader :end

      def initialize(id: nil, start: nil, end_time: nil, text: nil, translation: nil, **kwargs)
        super()
        @id = id
        @start = start
        @end = end_time.nil? ? (kwargs[:end] || kwargs["end"]) : end_time
        @text = text
        @translation = translation
      end
    end

    # Audio text result for transcript translation
    class AudioTextResult < Base
      attr_reader :id, :source, :target, :filename, :duration, :text, :translation, :segments

      def initialize(id: nil, source: nil, target: nil, filename: nil, duration: nil, text: nil,
                     translation: nil, segments: nil, **_kwargs)
        super()
        @id = id
        @source = source
        @target = target
        @filename = filename
        @duration = duration
        @text = text
        @translation = translation
        @segments = Array(segments).map do |seg|
          if seg.is_a?(Hash)
            AudioTextSegment.new(
              id: seg["id"] || seg[:id],
              start: seg["start"] || seg[:start],
              end_time: seg["end"] || seg[:end],
              text: seg["text"] || seg[:text],
              translation: seg["translation"] || seg[:translation]
            )
          else
            seg
          end
        end
      end
    end
  end
end
