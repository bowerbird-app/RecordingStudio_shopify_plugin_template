# frozen_string_literal: true

require "test_helper"
require "json"
require "uri"

class ShopifyShopMetafieldsTest < Minitest::Test
  FakeClient = Struct.new(:session_token_audience, :session_token_secret)

  class FakeHttp
    attr_reader :calls, :mode

    def initialize(mode: :happy)
      @mode = mode
      @calls = []
    end

    def post(url, body:, headers:)
      @calls << { url: url, body: body, headers: headers }
      return { "access_token" => "shpat_test" } if url.include?("access_token")

      graphql_response(body)
    end

    private

    def graphql_response(body)
      return top_level_error if mode == :graphql_error
      return verify_response if body.include?("VerifyRecordingStudioAppMetafields")
      return installation_response if body.include?("currentAppInstallation")
      return definition_response if body.include?("metafieldDefinitionCreate")
      return metafields_set_response if body.include?("metafieldsSet")

      { "data" => {} }
    end

    def top_level_error
      { "errors" => [{ "message" => "mutation failed" }], "data" => nil }
    end

    def installation_response
      { "data" => { "currentAppInstallation" => { "id" => "gid://shopify/AppInstallation/1" } } }
    end

    def definition_response
      { "data" => { "metafieldDefinitionCreate" => { "userErrors" => [] } } }
    end

    def metafields_set_response
      case mode
      when :hollow_set
        { "data" => { "metafieldsSet" => nil } }
      else
        { "data" => { "metafieldsSet" => { "userErrors" => [] } } }
      end
    end

    def verify_response
      case mode
      when :blank_readback
        {
          "data" => {
            "currentAppInstallation" => {
              "hostBaseUrl" => { "value" => "" },
              "storefrontToken" => { "value" => "" }
            }
          }
        }
      else
        {
          "data" => {
            "currentAppInstallation" => {
              "hostBaseUrl" => { "value" => "https://dummy.example" },
              "storefrontToken" => { "value" => "shop-token" }
            }
          }
        }
      end
    end
  end

  def test_writes_host_token_and_pages_on_app_installation
    http = FakeHttp.new
    client = FakeClient.new("partner-app", "partner-secret")

    result = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.sync!(
      request: RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldRequest.new(
        shop_domain: "demo.myshopify.com",
        client: client,
        session_token: "session-jwt",
        host_base_url: "https://dummy.example",
        storefront_token: "shop-token",
        pages: [{ "id" => "page-1", "title" => "Getting Started" }]
      ),
      http: http
    )

    assert result.ok?
    set_call = http.calls.find { |call| call.fetch(:body).include?("metafieldsSet") }
    assert_includes set_call.fetch(:body), "gid://shopify/AppInstallation/1"
    assert_includes set_call.fetch(:body), "host_base_url"
    assert_includes set_call.fetch(:body), "storefront_token"
    assert_includes set_call.fetch(:body), "Getting Started"
    assert_includes set_call.fetch(:body), "$app:recording_studio"
  end

  def test_token_exchange_body_uses_ietf_grant_type
    http = FakeHttp.new
    client = FakeClient.new("partner-app", "partner-secret")

    RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.sync!(
      request: RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldRequest.new(
        shop_domain: "demo.myshopify.com",
        client: client,
        session_token: "session-jwt",
        host_base_url: "https://dummy.example",
        storefront_token: "shop-token",
        pages: []
      ),
      http: http
    )

    token_call = http.calls.find { |call| call.fetch(:url).include?("access_token") }
    params = URI.decode_www_form(token_call.fetch(:body)).to_h
    assert_equal "urn:ietf:params:oauth:grant-type:token-exchange", params.fetch("grant_type")
  end

  def test_blank_session_token_fails_without_http
    http = FakeHttp.new
    client = FakeClient.new("partner-app", "partner-secret")

    result = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.sync!(
      request: RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldRequest.new(
        shop_domain: "demo.myshopify.com",
        client: client,
        session_token: "",
        host_base_url: "https://dummy.example",
        storefront_token: "shop-token",
        pages: []
      ),
      http: http
    )

    refute result.ok?
    assert_equal "session token required", result.error
    assert_empty http.calls
  end

  def test_hollow_metafields_set_is_not_ok
    http = FakeHttp.new(mode: :hollow_set)
    client = FakeClient.new("partner-app", "partner-secret")

    result = sync_with(http, client)

    refute result.ok?
    assert_equal "metafieldsSet missing", result.error
  end

  def test_read_back_blank_is_not_ok
    http = FakeHttp.new(mode: :blank_readback)
    client = FakeClient.new("partner-app", "partner-secret")

    result = sync_with(http, client)

    refute result.ok?
    assert_equal "host_base_url metafield blank after write", result.error
  end

  def test_graphql_top_level_errors_are_not_ok
    http = FakeHttp.new(mode: :graphql_error)
    client = FakeClient.new("partner-app", "partner-secret")

    result = sync_with(http, client)

    refute result.ok?
    assert_equal "mutation failed", result.error
  end

  private

  def sync_with(http, client)
    RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.sync!(
      request: RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldRequest.new(
        shop_domain: "demo.myshopify.com",
        client: client,
        session_token: "session-jwt",
        host_base_url: "https://dummy.example",
        storefront_token: "shop-token",
        pages: []
      ),
      http: http
    )
  end
end
