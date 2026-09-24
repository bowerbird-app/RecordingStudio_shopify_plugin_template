# frozen_string_literal: true

require "test_helper"

class ShopifyCliScaffoldTest < ActiveSupport::TestCase
  test "shopify CLI shell files exist" do
    root = RecordingStudioShopifyPluginTemplate::Engine.root.join("shopify")

    assert File.exist?(root.join("shopify.app.toml"))
    assert File.exist?(root.join("app-home/index.html"))
    assert File.exist?(root.join("app-home/app-bridge.js"))
    assert File.exist?(root.join("extensions/recording-studio-theme/blocks/recording-studio.liquid"))
    toml = File.read(root.join("shopify.app.toml"))
    liquid = File.read(root.join("extensions/recording-studio-theme/blocks/recording-studio.liquid"))
    home = File.read(root.join("app-home/index.html"))
    bridge = File.read(root.join("app-home/app-bridge.js"))

    assert_includes toml, "app/uninstalled"
    assert_includes toml, "/shopify_plugin_demo/uninstall"
    assert_includes toml, "embedded = true"
    assert_includes home, "iframe"
    assert_includes bridge, "shopify_session_token"
    assert_includes bridge, "HOST_BASE_URL"
    assert_includes liquid, "data-rs-page-id"
    assert_includes liquid, "shop.permanent_domain"
    assert_includes liquid, "embed.js"
    assert_includes liquid, "embed_token"
    assert_includes liquid, "request.design_mode"
    assert_includes liquid, "Nothing to show here yet."
    refute_includes liquid, "<iframe"
    refute_includes liquid, "iframe"
  end
end
