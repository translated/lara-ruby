# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    class Glossary < Base
      attr_reader :id, :name, :owner_id, :created_at, :updated_at, :shared_at, :is_personal

      def initialize(id:, name:, owner_id:, created_at: nil, updated_at: nil, shared_at: nil,
                     is_personal: nil, **_kwargs)
        super()
        @id = id
        @name = name
        @owner_id = owner_id
        @created_at = Base.parse_time(created_at)
        @updated_at = Base.parse_time(updated_at)
        @shared_at = Base.parse_time(shared_at)
        @is_personal = is_personal.nil? ? _kwargs[:isPersonal] : is_personal
      end
    end

    class GlossaryImport < Base
      attr_reader :id, :range_begin, :range_end, :channel, :size, :progress

      def initialize(id:, channel:, size:, progress:, range_begin: nil, range_end: nil, **kwargs)
        super()
        @id = id
        @range_begin = range_begin.nil? ? (kwargs[:begin] || kwargs["begin"]) : range_begin
        @range_end = range_end.nil? ? (kwargs[:end] || kwargs["end"]) : range_end
        @channel = channel
        @size = size
        @progress = progress
      end
    end

    class GlossaryCounts < Base
      attr_reader :unidirectional, :multidirectional

      def initialize(unidirectional: nil, multidirectional: nil)
        super()
        @unidirectional = unidirectional
        @multidirectional = multidirectional
      end
    end
  end
end
