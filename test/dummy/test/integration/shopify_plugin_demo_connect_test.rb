# frozen_string_literal: true

require "test_helper"
require "base64"
require "devise/test/integration_helpers"
require "openssl"

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

  test "connect post form uses a submit button for app home" do
    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    assert_select "form[action=?] button[type=submit]", shopify_plugin_demo_connect_path(shop: "demo.myshopify.com") do
      assert_select "button", text: ShopifyPluginDemo::ProductConfig::CONNECT_BUTTON_TEXT
    end
  end

  test "connect form keeps id_token as a hidden session token" do
    token = session_token_for(shop: "demo.myshopify.com")

    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com", id_token: token }

    assert_response :success
    assert_select "input[type=hidden][name=shopify_session_token][value=?]", token
    assert_select "form[action=?] button[type=submit]", shopify_plugin_demo_connect_path(shop: "demo.myshopify.com")
  end

  test "connect post with id_token publishes storefront metafields" do
    token = session_token_for(shop: "demo.myshopify.com")
    captured = nil
    publisher = ShopifyPluginDemo::PublishStorefrontMetafields
    singleton = publisher.singleton_class
    singleton.alias_method :__orig_call, :call
    singleton.define_method(:call) do |**kwargs|
      captured = kwargs
      nil
    end

    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com", id_token: token }
    post shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com", id_token: token }

    assert captured
    assert_equal token, captured.fetch(:session_token)
    assert_equal "demo.myshopify.com", captured.fetch(:shop_domain)
  ensure
    if defined?(singleton) && singleton.method_defined?(:__orig_call)
      singleton.alias_method :call, :__orig_call
      singleton.remove_method :__orig_call
    end
  end

  test "connected connect screen hides installed is not connected" do
    token = session_token_for(shop: "demo.myshopify.com")
    get shopify_plugin_demo_connect_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: token
    }
    post shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    get shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    refute_includes response.body, "Installed is not Connected"
    assert_includes response.body, "This shop is Connected to Recording Studio."
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
    get shopify_plugin_demo_connect_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: session_token_for(shop: "demo.myshopify.com")
    }

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

  test "bind without a prior install fails" do
    post shopify_plugin_demo_connect_path, params: { shop: "demo.myshopify.com" }
    follow_redirect!

    assert_includes response.body, "install required"
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
  end

  test "signed uninstall webhook removes the install without session" do
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "gone.myshopify.com"),
      client: @client
    )
    assert result.ok?

    post_uninstall_webhook(shop: "gone.myshopify.com")

    assert_response :ok
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "gone.myshopify.com",
      client: @client
    )
  end

  test "forged uninstall webhook does not remove the install" do
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "keep.myshopify.com"),
      client: @client
    )
    assert result.ok?

    post "/shopify_plugin_demo/uninstall",
         params: { shop: "keep.myshopify.com" }.to_json,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "HTTP_X_SHOPIFY_HMAC_SHA256" => "forged"
         }

    assert_response :unauthorized
    assert RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "keep.myshopify.com",
      client: @client
    )
  end

  test "unsigned uninstall webhook does not remove the install" do
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "unsigned.myshopify.com"),
      client: @client
    )
    assert result.ok?

    post "/shopify_plugin_demo/uninstall", params: { shop: "unsigned.myshopify.com" }

    assert_response :unauthorized
    assert RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "unsigned.myshopify.com",
      client: @client
    )
  end

  test "remove without client does not delete an install" do
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "keep.myshopify.com"),
      client: @client
    )
    assert result.ok?

    denied = RecordingStudioShopifyPluginTemplate::ShopifyInstall.remove(shop_domain: "keep.myshopify.com")

    refute denied.ok?
    assert_equal "client required", denied.error
    assert RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "keep.myshopify.com",
      client: @client
    )
  end

  test "remove with client only deletes that client's install" do
    other = create_registered_app(name: "Other Shopify plugin", audience: "other-partner-app", secret: "other-secret")
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "shared.myshopify.com"),
      client: @client
    )
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: session_token_for(shop: "shared.myshopify.com", audience: "other-partner-app", secret: "other-secret"),
      client: other
    )

    removed = RecordingStudioShopifyPluginTemplate::ShopifyInstall.remove(
      shop_domain: "shared.myshopify.com",
      client: @client
    )

    assert removed.ok?
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "shared.myshopify.com",
      client: @client
    )
    assert RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "shared.myshopify.com",
      client: other
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

  def create_registered_app(name: "Shopify plugin", audience: PARTNER_APP_ID, secret: SESSION_SECRET)
    result = RecordingStudioOauth::Services::CreateOauthClient.call(
      name: name,
      redirect_uris: ["https://example.com/callback"],
      confidential: false,
      session_token_provider: "shopify",
      session_token_audience: audience,
      session_token_secret: secret
    )
    raise result.error unless result.success?

    result.value.fetch(:client)
  end

  def post_uninstall_webhook(shop:, secret: SESSION_SECRET)
    body = { shop: shop }.to_json
    hmac = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, body))
    post "/shopify_plugin_demo/uninstall",
         params: body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "HTTP_X_SHOPIFY_HMAC_SHA256" => hmac
         }
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
