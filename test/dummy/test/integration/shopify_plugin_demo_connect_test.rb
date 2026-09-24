# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ShopifyPluginDemoConnectTest < ActionDispatch::IntegrationTest
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

  test "connect screen is reachable when signed in" do
    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::NAME
    assert_includes response.body, "Installed is not Connected"
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::CONNECT_BUTTON_TEXT
    assert_select "body[data-dummy-host-layout='true']", count: 1
    assert_includes response.body, "flat-pack--sidebar-layout"
  end

  test "verified session token records install without connecting" do
    token = session_token_for(shop: "demo.myshopify.com")

    get shopify_plugin_demo_connect_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: token
    }

    assert_response :success
    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert_equal "demo.myshopify.com", install.external_id
    assert_equal "shopify", install.provider
    refute install.connected?
    refute_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT
  end

  test "mismatched shop claims fail in the shell and do not record an install" do
    token = session_token_for(shop: "demo.myshopify.com")

    get shopify_plugin_demo_connect_path, params: {
      shop: "other.myshopify.com",
      shopify_session_token: token
    }

    assert_response :success
    assert_includes response.body, "shop does not match"
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "other.myshopify.com",
      client: @client
    )
  end

  test "connect then disconnect keeps the install row" do
    post shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert install.connected?
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT

    delete shopify_plugin_demo_disconnect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    install.reload
    refute install.connected?
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::CONNECT_BUTTON_TEXT
  end

  test "uninstall webhook removes the install without session" do
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
      shop_domain: "gone.myshopify.com",
      client: @client,
      root_recording: RecordingStudio.root_recording_for(Workspace.find_by!(name: "Studio Workspace")),
      connected_by: @user
    )

    post "/shopify_plugin_demo/uninstall", params: { shop: "gone.myshopify.com" }

    assert_response :ok
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "gone.myshopify.com",
      client: @client
    )
  end

  test "connect CSP allows Shopify admin frame ancestors" do
    get shopify_plugin_demo_connect_path

    csp = response.headers["Content-Security-Policy"].to_s
    assert_includes csp, "https://admin.shopify.com"
    assert_includes csp, "https://*.myshopify.com"
    assert_nil response.headers["X-Frame-Options"]
  end

  test "Page enables Embeddable for browser payloads" do
    source = File.read(Rails.root.join("config/initializers/recording_studio_api.rb"))
    order = ShopifyPluginDemo::Contract.parse_soft_register_order!(source)

    assert order.valid?
    assert_nothing_raised { ShopifyPluginDemo::Contract.assert_gem_owned_embed_handler! }
    assert_includes File.read(Rails.root.join("app/models/page.rb")), "Capabilities::Embeddable"
  end

  private

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
