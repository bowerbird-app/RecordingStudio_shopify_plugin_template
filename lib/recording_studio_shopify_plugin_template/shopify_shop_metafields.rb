# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module RecordingStudioShopifyPluginTemplate
  class ShopifyShopMetafields
    NAMESPACE = "$app:recording_studio"
    API_VERSION = "2025-01"
    TOKEN_GRANT = "urn:shopify:params:oauth:grant-type:token-exchange"
    SUBJECT_TOKEN_TYPE = "urn:ietf:params:oauth:token-type:id_token"
    REQUESTED_TOKEN_TYPE = "urn:shopify:params:oauth:token-type:offline-access-token"

    Result = Struct.new(:success, :error, keyword_init: true) do
      def ok?
        success
      end
    end

    def self.sync!(shop_domain:, client:, session_token:, host_base_url:, storefront_token:, pages:, http: nil)
      new(
        shop_domain: shop_domain,
        client: client,
        session_token: session_token,
        host_base_url: host_base_url,
        storefront_token: storefront_token,
        pages: pages,
        http: http
      ).sync!
    end

    def initialize(shop_domain:, client:, session_token:, host_base_url:, storefront_token:, pages:, http:)
      @shop_domain = ShopifySessionClaims.normalize_shop(shop_domain)
      @client = client
      @session_token = session_token.to_s
      @host_base_url = host_base_url.to_s.sub(%r{/\z}, "")
      @storefront_token = storefront_token.to_s
      @pages = Array(pages)
      @http = http || Http
    end

    def sync!
      return Result.new(success: false, error: "shop required") if @shop_domain.blank?
      return Result.new(success: false, error: "session token required") if @session_token.blank?
      return Result.new(success: false, error: "client required") if @client.blank?
      return Result.new(success: false, error: "host required") if @host_base_url.blank?
      return Result.new(success: false, error: "token required") if @storefront_token.blank?

      access_token = exchange_access_token
      return access_token unless access_token.ok?

      shop_id = shop_gid(access_token.error)
      return shop_id unless shop_id.ok?

      write_metafields(access_token.error, shop_id.error)
    end

    private

    def exchange_access_token
      body = URI.encode_www_form(
        client_id: @client.session_token_audience,
        client_secret: @client.session_token_secret,
        grant_type: TOKEN_GRANT,
        subject_token: @session_token,
        subject_token_type: SUBJECT_TOKEN_TYPE,
        requested_token_type: REQUESTED_TOKEN_TYPE
      )
      payload = @http.post(
        "https://#{@shop_domain}/admin/oauth/access_token",
        body: body,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )
      token = payload["access_token"].to_s
      return Result.new(success: false, error: "access token missing") if token.blank?

      Result.new(success: true, error: token)
    rescue StandardError => e
      Result.new(success: false, error: e.message)
    end

    def shop_gid(access_token)
      payload = graphql(access_token, { query: "{ shop { id } }" })
      gid = payload.dig("data", "shop", "id").to_s
      return Result.new(success: false, error: "shop id missing") if gid.blank?

      Result.new(success: true, error: gid)
    rescue StandardError => e
      Result.new(success: false, error: e.message)
    end

    def write_metafields(access_token, shop_gid)
      payload = graphql(access_token, {
        query: <<~GRAPHQL,
          mutation MetafieldsSet($metafields: [MetafieldsSetInput!]!) {
            metafieldsSet(metafields: $metafields) {
              userErrors { field message }
            }
          }
        GRAPHQL
        variables: { metafields: metafield_inputs(shop_gid) }
      })
      errors = Array(payload.dig("data", "metafieldsSet", "userErrors"))
      return Result.new(success: false, error: errors.map { |row| row["message"] }.join(", ")) if errors.any?

      Result.new(success: true, error: nil)
    rescue StandardError => e
      Result.new(success: false, error: e.message)
    end

    def metafield_inputs(shop_gid)
      [
        metafield(shop_gid, "host_base_url", "single_line_text_field", @host_base_url),
        metafield(shop_gid, "storefront_token", "single_line_text_field", @storefront_token),
        metafield(shop_gid, "pages", "json", JSON.generate(@pages))
      ]
    end

    def metafield(owner_id, key, type, value)
      {
        ownerId: owner_id,
        namespace: NAMESPACE,
        key: key,
        type: type,
        value: value
      }
    end

    def graphql(access_token, body)
      @http.post(
        "https://#{@shop_domain}/admin/api/#{API_VERSION}/graphql.json",
        body: JSON.generate(body),
        headers: {
          "Content-Type" => "application/json",
          "X-Shopify-Access-Token" => access_token
        }
      )
    end

    module Http
      module_function

      def post(url, body:, headers:)
        uri = URI(url)
        request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| request[key] = value }
        request.body = body
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end
        JSON.parse(response.body.to_s.presence || "{}")
      end
    end
  end
end
