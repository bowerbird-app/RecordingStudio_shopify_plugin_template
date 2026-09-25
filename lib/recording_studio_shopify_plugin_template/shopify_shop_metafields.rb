# frozen_string_literal: true

require "json"
require "uri"

module RecordingStudioShopifyPluginTemplate
  class ShopifyShopMetafields
    API_VERSION = "2025-01"
    TOKEN_GRANT = "urn:shopify:params:oauth:grant-type:token-exchange"
    SUBJECT_TOKEN_TYPE = "urn:ietf:params:oauth:token-type:id_token"
    REQUESTED_TOKEN_TYPE = "urn:shopify:params:oauth:token-type:offline-access-token"

    Request = Data.define(:shop_domain, :client, :session_token, :host_base_url, :storefront_token, :pages)
    Result = Data.define(:success, :error) do
      def ok? = success
    end

    def self.sync!(request:, http: nil)
      new(request: request, http: http).sync!
    end

    def initialize(request:, http: nil)
      @request = request
      @shop_domain = ShopifySessionClaims.normalize_shop(request.shop_domain)
      @host_base_url = request.host_base_url.to_s.sub(%r{/\z}, "")
      @http = http || ShopifyAdminHttp
    end

    def sync!
      missing = missing_input
      return fail_with(missing) if missing

      access_token = exchange_access_token
      return access_token unless access_token.ok?

      shop_id = shop_gid(access_token.error)
      return shop_id unless shop_id.ok?

      write_metafields(access_token.error, shop_id.error)
    end

    private

    def missing_input
      return "shop required" if @shop_domain.blank?
      return "session token required" if @request.session_token.to_s.blank?
      return "client required" if @request.client.blank?
      return "host required" if @host_base_url.blank?
      return "token required" if @request.storefront_token.to_s.blank?

      nil
    end

    def exchange_access_token
      payload = @http.post(
        "https://#{@shop_domain}/admin/oauth/access_token",
        body: token_exchange_body,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )
      token = payload["access_token"].to_s
      token.blank? ? fail_with("access token missing") : Result.new(success: true, error: token)
    rescue StandardError => e
      fail_with(e.message)
    end

    def token_exchange_body
      URI.encode_www_form(
        client_id: @request.client.session_token_audience,
        client_secret: @request.client.session_token_secret,
        grant_type: TOKEN_GRANT,
        subject_token: @request.session_token.to_s,
        subject_token_type: SUBJECT_TOKEN_TYPE,
        requested_token_type: REQUESTED_TOKEN_TYPE
      )
    end

    def shop_gid(access_token)
      gid = graphql(access_token, { query: "{ shop { id } }" }).dig("data", "shop", "id").to_s
      gid.blank? ? fail_with("shop id missing") : Result.new(success: true, error: gid)
    rescue StandardError => e
      fail_with(e.message)
    end

    def write_metafields(access_token, shop_gid)
      payload = ShopifyShopMetafieldPayload.set_payload(
        shop_gid,
        host_base_url: @host_base_url,
        storefront_token: @request.storefront_token.to_s,
        pages: @request.pages
      )
      errors = Array(graphql(access_token, payload).dig("data", "metafieldsSet", "userErrors"))
      return fail_with(errors.map { |row| row["message"] }.join(", ")) if errors.any?

      Result.new(success: true, error: nil)
    rescue StandardError => e
      fail_with(e.message)
    end

    def graphql(access_token, body)
      @http.post(
        "https://#{@shop_domain}/admin/api/#{API_VERSION}/graphql.json",
        body: JSON.generate(body),
        headers: { "Content-Type" => "application/json", "X-Shopify-Access-Token" => access_token }
      )
    end

    def fail_with(message)
      Result.new(success: false, error: message)
    end
  end
end
