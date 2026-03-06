# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    module DocumentStatus
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

    # Extraction parameters for DOCX files
    class DocxExtractionParams
      attr_reader :extract_comments, :accept_revisions

      def initialize(extract_comments: nil, accept_revisions: nil)
        @extract_comments = extract_comments
        @accept_revisions = accept_revisions
      end

      def to_h
        {
          extract_comments: @extract_comments,
          accept_revisions: @accept_revisions
        }.compact
      end
    end

    class Document < Base
      attr_reader :id, :status, :source, :target, :filename, :created_at, :updated_at,
                  :options, :translated_chars, :total_chars, :error_reason

      def initialize(id:, status:, filename:, target: nil, source: nil, created_at: nil, updated_at: nil,
                     options: nil, translated_chars: nil, total_chars: nil, error_reason: nil)
        super()
        @id = id
        @status = status
        @source = source
        @target = target
        @filename = filename
        @created_at = Base.parse_time(created_at)
        @updated_at = Base.parse_time(updated_at)
        @options = options
        @translated_chars = translated_chars&.to_i
        @total_chars = total_chars&.to_i
        @error_reason = error_reason
      end
    end
  end
end
