# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PluginSettingsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PARTNER_APP_ID = "shopify-partner-app-id"
  SESSION_SECRET = "shopify-session-token-secret"

  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Workspace.find_or_create_by!(name: "Studio Workspace")
    @client = create_registered_app
    RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id = @client.client_id
    sign_in @user
  end

  teardown do
    RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id = nil
  end

  test "not connected redirects to connect" do
    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_redirected_to shopify_plugin_demo_connect_path(shop: "demo.myshopify.com")
  end

  test "connected shows disconnect" do
    connect_shop!("demo.myshopify.com")

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_TITLE
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT
    assert_select "form.button_to input[name=_method][value=delete]", count: 1
    assert_select "form.button_to[action=?]", shopify_plugin_demo_disconnect_path(shop: "demo.myshopify.com")
  end

  test "disconnect from plugin settings soft-disconnects" do
    connect_shop!("demo.myshopify.com")

    delete shopify_plugin_demo_disconnect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert install
    refute install.connected?

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_redirected_to shopify_plugin_demo_connect_path(shop: "demo.myshopify.com")
  end

  private

  def connect_shop!(shop)
    token = session_token_for(shop: shop)
    get shopify_plugin_demo_connect_path, params: {
      shop: shop,
      shopify_session_token: token
    }
    post shopify_plugin_demo_connect_path, params: { shop: shop }
  end

  def create_registered_app
    result = RecordingStudioOauth::Services::CreateOauthClient.call(
      name: "Shopify plugin",
      redirect_uris: ["https://example.com/callback"],
      confidential: false,
      session_token_provider: "shopify",
      session_token_audience: PARTNER_APP_ID,
      session_token_secret: SESSION_SECRET
    )
    raise result.error unless result.success?

    result.value.fetch(:client)
  end

  def session_token_for(shop:)
    now = Time.now.to_i
    RecordingStudioOauth::Hs256Jwt.encode(
      {
        "aud" => PARTNER_APP_ID,
        "dest" => "https://#{shop}",
        "iss" => "https://#{shop}/admin",
        "nbf" => now - 5,
        "exp" => now + 60
      },
      SESSION_SECRET
    )
  end
end
