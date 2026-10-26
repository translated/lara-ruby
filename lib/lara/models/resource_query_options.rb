# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    # Optional name filtering and pagination for resource collections.
    class ResourceQueryOptions < Base
      # @return [String,nil] Filter by visible name (1-255 characters)
      attr_reader :search
      # @return [Integer,nil] Page number (1-based); enables pagination when supplied
      attr_reader :page
      # @return [Integer,nil] Page size (1-200); enables pagination when supplied
      attr_reader :size

      def initialize(search: nil, page: nil, size: nil)
        super()
        @search = search
        @page = page
        @size = size
      end

      # @return [Hash] Supplied options; validation and defaults are handled by the API
      def to_params
        { search: search, page: page, size: size }.compact
      end
    end
  end
end
