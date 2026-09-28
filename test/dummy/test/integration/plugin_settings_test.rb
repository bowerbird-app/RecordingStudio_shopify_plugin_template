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

  test "connect success lands on plugin settings" do
    token = session_token_for(shop: "demo.myshopify.com")
    stub_shopify_shop_metafields_ok
    get shopify_plugin_demo_connect_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: token
    }

    post shopify_plugin_demo_connect_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: token
    }

    assert_response :redirect
    assert_includes response.redirect_url, plugin_settings_path
    follow_redirect!
    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_TITLE
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED
  ensure
    restore_shopify_shop_metafields
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
    disconnect_path = shopify_plugin_demo_disconnect_path(shop: "demo.myshopify.com")
    assert_select "form[action=?] input[name=_method][value=delete]", disconnect_path, count: 1
    assert_select "form[action=?] button[type=submit]", disconnect_path, count: 1
    assert_select "form[action=?] button button", disconnect_path, count: 0
    assert_select "form.button_to", count: 0
    assert_select "body[data-plugin-settings-layout='true']", count: 1
    assert_select "[data-storage-key='shopify-plugin-demo-sidebar']", count: 0
    refute_includes response.body, "shopify-plugin-demo-sidebar"
    assert_select "main.flex.items-center.justify-center", count: 1
    assert_select "[data-controller='flat-pack--toast']", text: /this is a test dummy route/, count: 1
  end

  test "disconnect from plugin settings soft-disconnects" do
    connect_shop!("demo.myshopify.com")

    delete shopify_plugin_demo_disconnect_path(shop: "demo.myshopify.com")

    assert_redirected_to shopify_plugin_demo_connect_path(shop: "demo.myshopify.com")
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Disconnected. The Shopify plugin can still be installed."

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

  def stub_shopify_shop_metafields_ok
    klass = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields
    singleton = klass.singleton_class
    return if singleton.method_defined?(:__orig_sync!)

    singleton.alias_method :__orig_sync!, :sync!
    singleton.define_method(:sync!) do |**|
      RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult.new(success: true, error: nil)
    end
  end

  def restore_shopify_shop_metafields
    klass = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields
    singleton = klass.singleton_class
    return unless singleton.method_defined?(:__orig_sync!)

    singleton.alias_method :sync!, :__orig_sync!
    singleton.remove_method :__orig_sync!
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
