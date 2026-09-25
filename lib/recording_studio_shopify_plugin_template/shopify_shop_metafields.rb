# frozen_string_literal: true

require "json"
require "uri"

module RecordingStudioShopifyPluginTemplate
  ShopifyShopMetafieldRequest = Data.define(
    :shop_domain, :client, :session_token, :host_base_url, :storefront_token, :pages
  )
  ShopifyShopMetafieldResult = Data.define(:success, :error) do
    def ok? = success
  end

  class ShopifyShopMetafields
    include ShopifyShopMetafieldSync

    TOKEN_GRANT = "urn:ietf:params:oauth:grant-type:token-exchange"
    SUBJECT_TOKEN_TYPE = "urn:ietf:params:oauth:token-type:id_token"
    REQUESTED_TOKEN_TYPE = "urn:shopify:params:oauth:token-type:offline-access-token"
    APP_INSTALLATION_QUERY = "{ currentAppInstallation { id } }"

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

      owner_id = app_installation_id(access_token.error)
      return owner_id unless owner_id.ok?

      definition_error = ensure_definitions(access_token.error)
      return definition_error if definition_error

      write_metafields(access_token.error, owner_id.error)
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
      token.blank? ? fail_with("access token missing") : ShopifyShopMetafieldResult.new(success: true, error: token)
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

    def app_installation_id(access_token)
      payload = graphql(access_token, { query: APP_INSTALLATION_QUERY })
      return payload if payload.is_a?(ShopifyShopMetafieldResult)

      gid = payload.dig("data", "currentAppInstallation", "id").to_s
      gid.blank? ? fail_with("app installation missing") : ShopifyShopMetafieldResult.new(success: true, error: gid)
    rescue StandardError => e
      fail_with(e.message)
    end
  end
end
