# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require_relative "../oauth_connect_test_helper"

class HomeStatusTest < ActionDispatch::IntegrationTest
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

  test "home without a shop still says not connected" do
    get root_path

    assert_response :success
    assert_includes response.body, "Partner install is not Connected"
    assert_includes response.body, plugin_settings_path
  end

  test "home shows connected copy when the shop is connected" do
    connect_shop!("demo.myshopify.com")

    get root_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    refute_includes response.body, "Partner install is not Connected"
  end

  test "open connect keeps shop and id_token" do
    token = session_token_for(shop: "demo.myshopify.com")

    get root_path, params: { shop: "demo.myshopify.com", id_token: token, embedded: "1" }

    assert_response :success
    assert_includes response.body, CGI.escape(token)
    assert_includes response.body, "demo.myshopify.com"
    assert_includes response.body, "embedded=1"
  end

  private

  def connect_shop!(shop)
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!(shop)
  ensure
    restore_shopify_shop_metafields
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
      redirect_uris: [ "https://example.com/callback" ],
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
