# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    # A resource collection and its server-provided pagination metadata.
    class CollectionResult < Base
      # @return [Array<Lara::Models::Memory,Lara::Models::Glossary,Lara::Models::Styleguide>]
      attr_reader :items
      # @return [Integer] Total number of matching resources
      attr_reader :total
      # @return [Integer,nil] Current page (1-based), or nil for an unbounded collection
      attr_reader :page
      # @return [Integer,nil] Page size, or nil for an unbounded collection
      attr_reader :size

      def initialize(items:, total:, page: nil, size: nil)
        super()
        @items = items
        @total = total
        @page = page
        @size = size
      end
    end
  end
end
