# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    class Memory < Base
      attr_reader :id, :created_at, :updated_at, :name, :external_id, :secret,
                  :owner_id, :collaborators_count, :shared_at, :is_personal

      def initialize(id:, name:, owner_id:, created_at: nil, updated_at: nil,
                     external_id: nil, secret: nil, collaborators_count: nil, shared_at: nil,
                     is_personal: nil, **_kwargs)
        super()
        @id = id
        @name = name
        @owner_id = owner_id
        @created_at = Base.parse_time(created_at)
        @updated_at = Base.parse_time(updated_at)
        @external_id = external_id
        @secret = secret
        @collaborators_count = collaborators_count
        @shared_at = Base.parse_time(shared_at)
        @is_personal = is_personal.nil? ? _kwargs[:isPersonal] : is_personal
      end
    end

    class MemoryImport < Base
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
  end
end
