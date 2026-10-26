# frozen_string_literal: true

module Lara
  class Styleguides
    def initialize(client)
      @client = client
    end

    # @deprecated Use #list_paginated instead.
    # @return [Array<Lara::Models::Styleguide>]
    def list
      warn "[DEPRECATION] list is deprecated; use list_paginated instead.", uplevel: 1
      (@client.get("/v2/styleguides") || []).map do |h|
        Lara::Models::Styleguide.new(**h.transform_keys(&:to_sym))
      end
    end

    # Lists resources with optional name filtering and pagination.
    # Without options, returns the complete collection without pagination.
    # Any supplied option enables pagination; page and size default to 1 and 20.
    # @param options [Lara::Models::ResourceQueryOptions,nil] Name filter and pagination
    # @return [Lara::Models::CollectionResult] Collection containing Styleguide objects
    def list_paginated(options = nil)
      params = options&.to_params || {}
      @client.get_collection("/v2/styleguides", params: params) do |item|
        Lara::Models::Styleguide.new(**item.transform_keys(&:to_sym))
      end
    end

    # @return [Lara::Models::Styleguide]
    def create(name:, content:)
      Lara::Models::Styleguide.new(**@client.post("/v2/styleguides",
                                                  body: { name: name,
                                                          content: content }).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Styleguide,nil]
    def get(id)
      Lara::Models::Styleguide.new(**@client.get("/v2/styleguides/#{id}").transform_keys(&:to_sym))
    rescue Lara::LaraApiError => e
      return nil if e.status_code == 404

      raise
    end

    # @return [Lara::Models::Styleguide]
    def update(id, name: nil, content: nil)
      Lara::Models::Styleguide.new(**@client.put("/v2/styleguides/#{id}",
                                                 body: { name: name,
                                                         content: content }.compact).transform_keys(&:to_sym))
    end

    # @return [Lara::Models::Styleguide]
    def delete(id)
      Lara::Models::Styleguide.new(**@client.delete("/v2/styleguides/#{id}").transform_keys(&:to_sym))
    end

    # @return [Lara::Models::StyleguideShares]
    def get_shares(id)
      Lara::Models::StyleguideShares.new(**@client.get("/v2/styleguides/#{id}/shares").transform_keys(&:to_sym))
    end

    def add_account_share(id, name: nil)
      styleguide_from(@client.post("/v2/styleguides/#{id}/shares", body: { name: name }.compact))
    end

    def rename_account_share(id, name:)
      styleguide_from(@client.put("/v2/styleguides/#{id}/shares", body: { name: name }))
    end

    def revoke_account_share(id)
      styleguide_from(@client.delete("/v2/styleguides/#{id}/shares"))
    end

    def add_group_share(id, group_id, name: nil)
      styleguide_from(@client.post("/v2/styleguides/#{id}/shares/groups/#{group_id}", body: { name: name }.compact))
    end

    def rename_group_share(id, group_id, name:)
      styleguide_from(@client.put("/v2/styleguides/#{id}/shares/groups/#{group_id}", body: { name: name }))
    end

    def revoke_group_share(id, group_id)
      styleguide_from(@client.delete("/v2/styleguides/#{id}/shares/groups/#{group_id}"))
    end

    private

    def styleguide_from(response)
      Lara::Models::Styleguide.new(**response.transform_keys(&:to_sym))
    end
  end
end
