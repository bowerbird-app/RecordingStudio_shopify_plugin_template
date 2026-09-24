# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ShopifyPluginDemoConnectTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    sign_in @user
  end

  test "connect screen is reachable when signed in" do
    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::NAME
    assert_includes response.body, "Installed is not Connected"
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::CONNECT_BUTTON_TEXT
  end

  test "connect then disconnect uses stub mapping table" do
    post shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    assert ShopifyPluginDemo::Connection.for_shop("demo.myshopify.com").connected?
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::DISCONNECT_BUTTON_TEXT

    delete shopify_plugin_demo_disconnect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    assert_nil ShopifyPluginDemo::Connection.for_shop("demo.myshopify.com")
  end

  test "uninstall webhook clears stub connection without session" do
    ShopifyPluginDemo::Connection.connect!("gone.myshopify.com")

    post "/shopify_plugin_demo/uninstall", params: { shop: "gone.myshopify.com" }

    assert_response :ok
    assert_nil ShopifyPluginDemo::Connection.for_shop("gone.myshopify.com")
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
end
