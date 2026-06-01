# frozen_string_literal: true

module Lara
  class Styleguides
    def initialize(client)
      @client = client
    end

    # @return [Array<Lara::Models::Styleguide>]
    def list
      (@client.get("/v2/styleguides") || []).map do |h|
        Lara::Models::Styleguide.new(**h.transform_keys(&:to_sym))
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
  end
end
