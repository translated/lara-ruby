# frozen_string_literal: true

require "time"

module Lara
  module Models
    # Base model providing common helpers for all SDK models.
    class Base
      # Converts a string timestamp to a Time object.
      def self.parse_time(value)
        return nil if value.nil?

        Time.iso8601(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
