# frozen_string_literal: true

require "test_helper"
require "base64"
require "cgi"
require "devise/test/integration_helpers"
require "openssl"
require_relative "../oauth_connect_test_helper"

class ShopifyPluginDemoConnectTest < ActionDispatch::IntegrationTest
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

  test "unconnected app home starts oauth authorize" do
    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
    follow_redirect!
    assert_response :success
    refute_includes response.body, "Shop domain"
    refute_includes response.body, "Use this shop"
    assert_select "body[data-dummy-host-layout='true']", count: 0
  end

  test "app home sign out returns to sign in after connect" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    assert_response :success
    delete destroy_user_session_path
    follow_redirect!
    follow_redirect! if response.redirect?

    assert_response :success
    assert_includes request.path, "sign_in"
    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_redirected_to new_user_session_path
  ensure
    restore_shopify_shop_metafields
  end

  test "oauth connect without session token binds and alerts that metafields did not sync" do
    token = session_token_for(shop: "demo.myshopify.com")
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: token,
      client: @client
    )

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }
    query = oauth_query_from(response.redirect_url)
    access = workspace_access_recording!
    get recording_studio_oauth.oauth_authorize_path(query.merge(access_recording_id: access.id))
    post recording_studio_oauth.oauth_authorize_path, params: query.merge(
      access_recording_id: access.id,
      role: "admin",
      decision: "connect"
    )
    follow_redirect!

    assert_includes response.redirect_url, plugin_settings_path
    follow_redirect!
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_FAILED
    assert_includes response.body, "session token required"
    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert install.connected?
  end

  test "oauth connect with session token and stubbed metafield sync notices settings" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    assert_response :success
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED
    assert_equal 1, response.body.scan(ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED).size
  ensure
    restore_shopify_shop_metafields
  end

  test "oauth connect without HOST_BASE_URL uses request base url not configuration" do
    previous_host = ENV["HOST_BASE_URL"]
    ENV.delete("HOST_BASE_URL")
    configuration_called = false
    RecordingStudioShopifyPluginTemplate.configuration.define_singleton_method(:host_base_url) do
      configuration_called = true
      raise NoMethodError, "configuration.host_base_url should not be called"
    end
    captured = nil
    publisher = ShopifyPluginDemo::PublishStorefrontMetafields
    singleton = publisher.singleton_class
    singleton.alias_method :__orig_call_host, :call unless singleton.method_defined?(:__orig_call_host)
    singleton.define_method(:call) do |**kwargs|
      captured = kwargs
      RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult.new(
        success: false,
        error: "session token required"
      )
    end
    complete_oauth_connect!("demo.myshopify.com")

    refute configuration_called
    assert_equal "http://www.example.com", captured.fetch(:host_base_url)
  ensure
    ENV["HOST_BASE_URL"] = previous_host if previous_host
    config = RecordingStudioShopifyPluginTemplate.configuration
    config.singleton_class.remove_method(:host_base_url) if config.singleton_methods.include?(:host_base_url)
    pub_singleton = ShopifyPluginDemo::PublishStorefrontMetafields.singleton_class
    if pub_singleton.method_defined?(:__orig_call_host)
      pub_singleton.alias_method :call, :__orig_call_host
      pub_singleton.remove_method :__orig_call_host
    end
  end

  test "oauth connect with id_token publishes storefront metafields" do
    token = session_token_for(shop: "demo.myshopify.com")
    captured = nil
    publisher = ShopifyPluginDemo::PublishStorefrontMetafields
    singleton = publisher.singleton_class
    singleton.alias_method :__orig_call, :call
    singleton.define_method(:call) do |**kwargs|
      captured = kwargs
      RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult.new(success: true, error: nil)
    end

    complete_oauth_connect!("demo.myshopify.com", token: token)

    assert captured
    assert_equal token, captured.fetch(:session_token)
    assert_equal "demo.myshopify.com", captured.fetch(:shop_domain)
    assert_equal plugin_settings_path, request.path
  ensure
    if defined?(singleton) && singleton.method_defined?(:__orig_call)
      singleton.alias_method :call, :__orig_call
      singleton.remove_method :__orig_call
    end
  end

  test "connected settings screen hides installed is not connected" do
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

    get plugin_settings_path, params: { shop: "demo.myshopify.com" }

    assert_response :success
    refute_includes response.body, "Installed is not Connected"
    assert_includes response.body, ShopifyPluginDemo::ProductConfig::SETTINGS_CONNECTED_STATUS
    refute_includes response.body, "Connect again"
    assert_includes CGI.unescapeHTML(response.body), ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_MISSING_TOKEN
  ensure
    restore_shopify_shop_metafields
  end

  test "verified session token records install without connecting" do
    token = session_token_for(shop: "demo.myshopify.com")

    get plugin_settings_path, params: {
      shop: "demo.myshopify.com",
      shopify_session_token: token
    }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
    install = RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: "demo.myshopify.com",
      client: @client
    )
    assert_equal "demo.myshopify.com", install.external_id
    assert_equal "shopify", install.provider
    refute install.connected?
  end

  test "mismatched shop claims fail in the shell and do not record an install" do
    token = session_token_for(shop: "demo.myshopify.com")

    get plugin_settings_path, params: {
      shop: "other.myshopify.com",
      shopify_session_token: token
    }

    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
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
    stub_shopify_shop_metafields_ok
    complete_oauth_connect!("demo.myshopify.com")

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
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
  ensure
    restore_shopify_shop_metafields
  end

  test "oauth finish without a prior install fails" do
    access = workspace_access_recording!
    get plugin_settings_path, params: { shop: "demo.myshopify.com" }
    query = oauth_query_from(response.redirect_url)
    get recording_studio_oauth.oauth_authorize_path(query.merge(access_recording_id: access.id))
    post recording_studio_oauth.oauth_authorize_path, params: query.merge(
      access_recording_id: access.id,
      role: "admin",
      decision: "connect"
    )
    follow_redirect!

    assert_response :redirect
    follow_redirect! if response.redirect?
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
    get plugin_settings_path

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
