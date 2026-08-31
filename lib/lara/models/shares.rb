# frozen_string_literal: true

require_relative "base"

module Lara
  module Models
    class ResourceShareEntry < Base
      attr_reader :id, :name, :share_name, :shared_at, :permissions

      def initialize(id:, name:, share_name:, shared_at:, permissions:, **_kwargs)
        super()
        @id = id
        @name = name
        @share_name = share_name
        @shared_at = Base.parse_time(shared_at)
        @permissions = permissions
      end
    end

    class MemoryShares < Base
      attr_reader :memory, :account, :groups, :users

      def initialize(memory:, account: nil, groups: [], users: [], **_kwargs)
        super()
        @memory = Memory.new(**memory.transform_keys(&:to_sym))
        @account = ResourceShareEntry.new(**account.transform_keys(&:to_sym)) if account
        @groups = groups.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
        @users = users.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
      end
    end

    class GlossaryShares < Base
      attr_reader :glossary, :account, :groups, :users

      def initialize(glossary:, account: nil, groups: [], users: [], **_kwargs)
        super()
        @glossary = Glossary.new(**glossary.transform_keys(&:to_sym))
        @account = ResourceShareEntry.new(**account.transform_keys(&:to_sym)) if account
        @groups = groups.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
        @users = users.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
      end
    end

    class StyleguideShares < Base
      attr_reader :styleguide, :account, :groups, :users

      def initialize(styleguide:, account: nil, groups: [], users: [], **_kwargs)
        super()
        @styleguide = Styleguide.new(**styleguide.transform_keys(&:to_sym))
        @account = ResourceShareEntry.new(**account.transform_keys(&:to_sym)) if account
        @groups = groups.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
        @users = users.map { |entry| ResourceShareEntry.new(**entry.transform_keys(&:to_sym)) }
      end
    end
  end
end
