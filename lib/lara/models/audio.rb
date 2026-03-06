# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
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
  end
end
