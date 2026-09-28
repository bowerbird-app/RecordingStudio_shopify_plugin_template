# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require_relative "../oauth_connect_test_helper"

class PluginSettingsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include OauthConnectTestHelper

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
    workspace_access_recording!
  end

  teardown do
    RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id = nil
  end

  test "not connected sends app home through oauth authorize" do
    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
    refute_includes response.redirect_url, plugin_settings_path
    query = oauth_query_from(response.redirect_url)
    assert_equal "code", query.fetch("response_type")
    assert_equal @client.client_id, query.fetch("client_id")
    assert_equal connect_callback_url, query.fetch("redirect_uri")
    assert_equal "S256", query.fetch("code_challenge_method")
    follow_redirect!
    assert_response :success
    assert_includes request.path, "/recording_studio_oauth/oauth/authorize"
  end

  test "legacy connect path starts oauth when not connected" do
    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
  end

  test "oauth success lands on plugin settings" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    assert_response :success
    assert_equal plugin_settings_path, request.path
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT
    refute_includes response.body, "Installed is not Connected"
  ensure
    restore_shopify_shop_metafields
  end

  test "oauth callback binds with ShopifyInstall then opens plugin settings" do
    stub_shopify_shop_metafields_ok
    token = session_token_for(shop: "demo.myshopify.com")
    access = workspace_access_recording!

    get plugin_settings_path, params: { shop: "demo.myshopify.com", shopify_session_token: token }
    query = oauth_query_from(response.redirect_url)
    get recording_studio_oauth.oauth_authorize_path(query.merge(access_recording_id: access.id))
    post recording_studio_oauth.oauth_authorize_path, params: query.merge(
      access_recording_id: access.id,
      role: "admin",
      decision: "connect"
    )

    assert_response :redirect
    assert_includes response.redirect_url, "/connect/callback"
    follow_redirect!
    assert_response :redirect
    assert_includes response.redirect_url, plugin_settings_path
    follow_redirect!
    assert_equal plugin_settings_path, request.path
    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert install.connected?
    refute RecordingStudioShopifyPluginTemplate.const_defined?(:ShopifyOauthConnect, false)
  ensure
    restore_shopify_shop_metafields
  end

  test "callback wiring uses ShopifyInstall not ShopifyOauthConnect" do
    callback = File.read(Rails.root.join("app/controllers/connect_callbacks_controller.rb"))
    concern = File.read(Rails.root.join("lib/shopify_plugin_demo/host_oauth_connect.rb"))

    assert_includes callback, "bind_after_oauth"
    refute_includes callback, "ShopifyOauthConnect"
    assert_includes concern, "ShopifyInstall.bind"
    refute_includes concern, "ShopifyOauthConnect"
    refute File.exist?(RecordingStudioShopifyPluginTemplate::Engine.root.join(
                         "lib/recording_studio_shopify_plugin_template/shopify_oauth_connect.rb"
                       ))
  end

  test "connected opens plugin settings without oauth" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_equal plugin_settings_path, request.path
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT
    refute_includes request.path, "/recording_studio_oauth/oauth/authorize"
  ensure
    restore_shopify_shop_metafields
  end

  test "connected shows disconnect" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    refute_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_TITLE
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT
    disconnect_path = plugin_settings_path(shop: "demo.myshopify.com")
    assert_select "form[action=?] input[name=_method][value=delete]", disconnect_path, count: 1
    assert_select "form[action=?] button[type=submit]", disconnect_path, count: 1
    assert_select "body[data-app-home-layout='true']", count: 1
  ensure
    restore_shopify_shop_metafields
  end

  test "disconnect from plugin settings requires oauth before settings again" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    delete plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_redirected_to plugin_settings_path(shop: "demo.myshopify.com")
    follow_redirect!
    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"

    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert install
    refute install.connected?

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
  ensure
    restore_shopify_shop_metafields
  end

  test "oauth connect preserves shop and embed query into session then settings" do
    token = session_token_for(shop: "demo.myshopify.com")
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com", token: token)

    assert_includes request.fullpath, "shop=demo.myshopify.com"
  ensure
    restore_shopify_shop_metafields
  end

  private

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
