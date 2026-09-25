# frozen_string_literal: true

require "test_helper"

class PublishStorefrontMetafieldsTest < ActiveSupport::TestCase
  test "blank session token returns a failed result" do
    result = ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: "demo.myshopify.com",
      client: Object.new,
      root_recording: nil,
      session_token: "  ",
      host_base_url: "http://example.test"
    )

    refute result.ok?
    assert_equal "session token required", result.error
  end

  test "blank minted token returns a failed result" do
    embed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed
    singleton = embed.singleton_class
    singleton.alias_method :__orig_secret_for, :secret_for
    singleton.alias_method :__orig_mint, :mint
    singleton.define_method(:secret_for) { |_client| "secret" }
    singleton.define_method(:mint) { |**| nil }

    result = ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: "demo.myshopify.com",
      client: Object.new,
      root_recording: nil,
      session_token: "session-token",
      host_base_url: "http://example.test"
    )

    refute result.ok?
    assert_equal "storefront token missing", result.error
  ensure
    restore_embed_methods
  end

  test "sync result is returned unchanged" do
    embed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed
    embed_singleton = embed.singleton_class
    embed_singleton.alias_method :__orig_secret_for, :secret_for
    embed_singleton.alias_method :__orig_mint, :mint
    embed_singleton.define_method(:secret_for) { |_client| "secret" }
    embed_singleton.define_method(:mint) { |**| "minted" }

    metafields = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields
    meta_singleton = metafields.singleton_class
    meta_singleton.alias_method :__orig_sync!, :sync!
    expected = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult.new(
      success: true,
      error: nil
    )
    meta_singleton.define_method(:sync!) { |**| expected }

    publisher = ShopifyPluginDemo::PublishStorefrontMetafields
    pub_singleton = publisher.singleton_class
    pub_singleton.alias_method :__orig_pages_for, :pages_for
    pub_singleton.define_method(:pages_for) { |_root| [] }

    result = publisher.call(
      shop_domain: "demo.myshopify.com",
      client: Object.new,
      root_recording: Object.new,
      session_token: "session-token",
      host_base_url: "http://example.test"
    )

    assert result.ok?
    assert_nil result.error
  ensure
    restore_embed_methods
    restore_metafield_sync
    restore_pages_for
  end

  private

  def restore_embed_methods
    embed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed
    singleton = embed.singleton_class
    if singleton.method_defined?(:__orig_secret_for)
      singleton.alias_method :secret_for, :__orig_secret_for
      singleton.remove_method :__orig_secret_for
    end
    return unless singleton.method_defined?(:__orig_mint)

    singleton.alias_method :mint, :__orig_mint
    singleton.remove_method :__orig_mint
  end

  def restore_metafield_sync
    klass = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields
    singleton = klass.singleton_class
    return unless singleton.method_defined?(:__orig_sync!)

    singleton.alias_method :sync!, :__orig_sync!
    singleton.remove_method :__orig_sync!
  end

  def restore_pages_for
    publisher = ShopifyPluginDemo::PublishStorefrontMetafields
    singleton = publisher.singleton_class
    return unless singleton.method_defined?(:__orig_pages_for)

    singleton.alias_method :pages_for, :__orig_pages_for
    singleton.remove_method :__orig_pages_for
  end
end
