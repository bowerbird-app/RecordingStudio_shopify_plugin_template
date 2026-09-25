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
    client = Object.new
    RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.stub(:secret_for, "secret") do
      RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.stub(:mint, nil) do
        result = ShopifyPluginDemo::PublishStorefrontMetafields.call(
          shop_domain: "demo.myshopify.com",
          client: client,
          root_recording: nil,
          session_token: "session-token",
          host_base_url: "http://example.test"
        )

        refute result.ok?
        assert_equal "storefront token missing", result.error
      end
    end
  end

  test "sync result is returned unchanged" do
    client = Object.new
    expected = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult.new(
      success: true,
      error: nil
    )
    RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.stub(:secret_for, "secret") do
      RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.stub(:mint, "minted") do
        ShopifyPluginDemo::PublishStorefrontMetafields.stub(:pages_for, []) do
          RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.stub(:sync!, expected) do
            result = ShopifyPluginDemo::PublishStorefrontMetafields.call(
              shop_domain: "demo.myshopify.com",
              client: client,
              root_recording: Object.new,
              session_token: "session-token",
              host_base_url: "http://example.test"
            )

            assert result.ok?
            assert_nil result.error
          end
        end
      end
    end
  end
end
