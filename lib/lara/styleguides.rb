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

    # @return [Lara::Models::Styleguide,nil]
    def get(id)
      Lara::Models::Styleguide.new(**@client.get("/v2/styleguides/#{id}").transform_keys(&:to_sym))
    rescue Lara::LaraApiError => e
      return nil if e.status_code == 404

      raise
    end
  end
end
