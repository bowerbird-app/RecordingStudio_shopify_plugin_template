# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ShopifyPluginDemoStorefrontEmbedTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PARTNER_APP_ID = "shopify-partner-app-id"
  SESSION_SECRET = "shopify-session-token-secret"
  SHOP = "demo.myshopify.com"

  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Workspace.find_or_create_by!(name: "Studio Workspace")
    @client = create_registered_app
    RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id = @client.client_id
    @provisioned = ShopifyPluginDemo::Provision.isolated_client!
    @page_recording = RecordingStudio::Recording.find(@provisioned.page_recording_id)
    connect_shop!(SHOP, root_recording: @page_recording.root_recording)
  end

  teardown do
    RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id = nil
  end

  test "storefront json rejects when the shop is not installed" do
    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :json),
        params: scoped_params(shop: "missing.myshopify.com")

    assert_response :not_found
    refute_includes response.body, "schema_version"
  end

  test "storefront json rejects when installed but not connected" do
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.unbind(shop_domain: SHOP, client: @client)

    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :json), params: scoped_params

    assert_response :not_found
  end

  test "storefront json rejects the wrong shop" do
    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :json),
        params: scoped_params.merge(shop: "other.myshopify.com")

    assert_response :not_found
  end

  test "storefront json rejects a page from another workspace" do
    foreign = ShopifyPluginDemo::Provision.foreign_page!

    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :json),
        params: scoped_params(page_id: foreign.id)

    assert_response :not_found
  end

  test "storefront json returns browser payload when connected" do
    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :json),
        params: scoped_params,
        headers: { "Accept" => "application/json" }

    assert_response :ok
    payload = ShopifyPluginDemo::Contract.parse_browser_payload!(JSON.parse(response.body))
    assert_equal 1, payload.schema_version
    assert_includes payload.html, "data-shopify-plugin-demo-embed"
    refute_includes payload.html, "<iframe"
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Cache-Control"], "max-age=60"
  end

  test "storefront js mounts html without an iframe" do
    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :js),
        params: scoped_params.merge(mount: "recording-studio-block")

    assert_response :ok
    assert_includes response.body, "getElementById(\"recording-studio-block\")"
    assert_includes response.body, "innerHTML"
    assert_includes response.body, "data-shopify-plugin-demo-embed"
    refute_includes response.body, "<iframe"
  end

  test "storefront js does not use an admin session cookie" do
    sign_in @user
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.unbind(shop_domain: SHOP, client: @client)

    get ShopifyPluginDemo::Contract.storefront_embed_path(format: :js), params: scoped_params

    assert_response :not_found
  end

  private

  def scoped_params(shop: SHOP, page_id: @page_recording.id)
    {
      shop: shop,
      page_id: page_id,
      token: mint_token(shop: shop, page_id: page_id)
    }
  end

  def mint_token(shop:, page_id:)
    RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: shop,
      page_recording_id: page_id,
      secret: RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(@client)
    )
  end

  def connect_shop!(shop, root_recording:)
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: shop),
      client: @client
    )
    raise result.error unless result.ok?

    bound = RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
      shop_domain: shop,
      client: @client,
      root_recording: root_recording,
      connected_by: @user
    )
    raise bound.error unless bound.ok?
  end

  def create_registered_app(name: "Shopify plugin", audience: PARTNER_APP_ID, secret: SESSION_SECRET)
    result = RecordingStudioOauth::Services::CreateOauthClient.call(
      name: name,
      redirect_uris: [ "https://example.com/callback" ],
      confidential: false,
      session_token_provider: "shopify",
      session_token_audience: audience,
      session_token_secret: secret
    )
    raise result.error unless result.success?

    result.value.fetch(:client)
  end

  def session_token_for(shop:, audience: PARTNER_APP_ID, secret: SESSION_SECRET)
    now = Time.now.to_i
    RecordingStudioOauth::Hs256Jwt.encode(
      {
        "aud" => audience,
        "dest" => "https://#{shop}",
        "iss" => "https://#{shop}/admin",
        "nbf" => now - 5,
        "exp" => now + 60
      },
      secret
    )
  end
end
