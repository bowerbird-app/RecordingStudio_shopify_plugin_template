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
    extension_toml = File.read(root.join("extensions/recording-studio-theme/shopify.extension.toml"))
    liquid = File.read(root.join("extensions/recording-studio-theme/blocks/recording-studio.liquid"))
    home = File.read(root.join("app-home/index.html"))
    bridge = File.read(root.join("app-home/app-bridge.js"))
    readme = File.read(root.join("README.md"))

    assert_includes toml, "application_url = \"https://example.com/plugin_settings\""
    assert_includes toml, "app/uninstalled"
    assert_includes toml, "/shopify_plugin_demo/uninstall"
    assert_includes toml, "embedded = true"
    assert_includes toml, "automatically_update_urls_on_dev = false"
    assert_includes home, "Shopify plugin settings"
    assert_includes extension_toml, "name = \"Recording Studio\""
    assert_includes extension_toml, "type = \"theme\""
    assert_includes extension_toml, "handle = \"recording-studio-theme\""
    refute_includes extension_toml, "[[extensions]]"
    refute_includes extension_toml, "uid = \"recording-studio-theme\""
    refute_match(/^uid\s*=/m, extension_toml)
    assert_includes readme, "Development store preview"
    assert_includes readme, "shopify app dev --no-update"
    assert_includes readme, "Add section → Apps"
    assert_includes readme, "plugin-test-74hpuu5t"
    assert_includes readme, "test-data"
    assert_includes liquid, "\"name\": \"Shopify plugin\""
    assert_includes liquid, "\"target\": \"section\""
    assert_includes bridge, "/plugin_settings"
    assert_includes bridge, "shopify_session_token"
    assert_includes bridge, "HOST_BASE_URL"
    assert_includes liquid, "shop.permanent_domain"
    assert_includes liquid, "embed.js"
    assert_includes liquid, "block.settings.page"
    assert_includes liquid, "Getting Started"
    assert_includes liquid, "Carousel"
    assert_includes liquid, 'app.metafields["$app:recording_studio"]'
    assert_includes liquid, '["host_base_url"]'
    assert_includes liquid, '["storefront_token"]'
    assert_includes liquid, '["pages"]'
    assert_includes liquid, "block.shopify_attributes"
    refute_includes liquid, "block.settings.host_base_url"
    refute_includes liquid, "block.settings.embed_token"
    refute_includes liquid, "block.settings.recording_id"
    assert_includes liquid, "request.design_mode"
    assert_includes liquid, "Nothing to show here yet."
    refute_includes liquid, "<iframe"
    refute_includes liquid, "iframe"
    assert_includes liquid, " defer"
    refute_includes liquid, " async"
    assert_includes liquid, "storefront/embed.css"
    assert_includes liquid, "storefront/embed_boot.js"
  end
end
