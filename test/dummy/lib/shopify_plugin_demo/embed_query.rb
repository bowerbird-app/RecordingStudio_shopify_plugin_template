# frozen_string_literal: true

module ShopifyPluginDemo
  module EmbedQuery
    KEYS = %i[shop host hmac id_token embedded shopify_session_token client_id].freeze

    module_function

    def from_params(params)
      {
        shop: params[:shop].presence || params[:shop_domain].presence,
        host: params[:host].presence,
        hmac: params[:hmac].presence,
        id_token: params[:id_token].presence,
        embedded: params[:embedded].presence,
        shopify_session_token: session_token(params),
        client_id: params[:client_id].presence
      }.compact
    end

    def session_token(params)
      params[:shopify_session_token].presence || params[:id_token].presence
    end
  end
end
