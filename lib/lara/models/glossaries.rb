# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    class Glossary < Base
      attr_reader :id, :name, :owner_id, :created_at, :updated_at, :shared_at, :is_personal, :permission_mask

      def initialize(id:, name:, owner_id:, created_at: nil, updated_at: nil, shared_at: nil,
                     is_personal: nil, permission_mask: nil, **_kwargs)
        super()
        @id = id
        @name = name
        @owner_id = owner_id
        @created_at = Base.parse_time(created_at)
        @updated_at = Base.parse_time(updated_at)
        @shared_at = Base.parse_time(shared_at)
        # The API sends is_personal: true and omits the key otherwise; it never sends false or null.
        @is_personal = is_personal || false
        # Effective combined mask in GET list/detail; selected share's stored mask in GET /shares.
        # Nil when omitted, including non-GET responses.
        @permission_mask = permission_mask
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

    class GlossaryExport < Base
      attr_reader :job_id

      def initialize(job_id:, **_kwargs)
        super()
        @job_id = job_id
      end
    end
  end
end
