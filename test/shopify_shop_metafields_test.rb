# frozen_string_literal: true

require "test_helper"
require "json"
require "uri"

class ShopifyShopMetafieldsTest < Minitest::Test
  FakeClient = Struct.new(:session_token_audience, :session_token_secret)

  class FakeHttp
    attr_reader :calls

    def initialize
      @calls = []
    end

    def post(url, body:, headers:)
      @calls << { url: url, body: body, headers: headers }
      if url.include?("access_token")
        { "access_token" => "shpat_test" }
      elsif body.include?("{ shop { id } }")
        { "data" => { "shop" => { "id" => "gid://shopify/Shop/1" } } }
      else
        { "data" => { "metafieldsSet" => { "userErrors" => [] } } }
      end
    end
  end

  def test_writes_host_token_and_pages
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
    assert_equal 3, http.calls.size
    mutation = http.calls.last.fetch(:body)
    assert_includes mutation, "host_base_url"
    assert_includes mutation, "storefront_token"
    assert_includes mutation, "Getting Started"
    assert_includes mutation, "$app:recording_studio"
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
    assert_equal "urn:ietf:params:oauth:token-type:id_token", params.fetch("subject_token_type")
    assert_equal "urn:shopify:params:oauth:token-type:offline-access-token", params.fetch("requested_token_type")
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
end
