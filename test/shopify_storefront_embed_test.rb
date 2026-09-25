# frozen_string_literal: true

require "test_helper"

class ShopifyStorefrontEmbedTest < Minitest::Test
  SECRET = "storefront-embed-secret"

  def test_mint_round_trips_shop
    token = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: "https://Demo.myshopify.com/admin",
      secret: SECRET
    )
    parsed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.parse(token, secret: SECRET)

    assert parsed.ok?
    assert_equal "demo.myshopify.com", parsed.shop_domain
    assert_nil parsed.page_recording_id
  end

  def test_tampered_token_fails_closed
    token = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: "demo.myshopify.com",
      secret: SECRET
    )
    parsed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.parse("#{token}x", secret: SECRET)

    refute parsed.ok?
    assert_equal "token invalid", parsed.error
  end

  def test_wrong_secret_fails_closed
    token = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: "demo.myshopify.com",
      secret: SECRET
    )
    parsed = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.parse(token, secret: "other")

    refute parsed.ok?
  end

  def test_blank_inputs_do_not_mint
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: "",
      secret: SECRET
    )
    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
      shop_domain: "demo.myshopify.com",
      secret: ""
    )
  end

  def test_secret_for_is_blank_without_session_secret
    client = Object.new
    def client.session_token_secret
      nil
    end

    assert_nil RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(client)
  end

  def test_secret_for_is_stable_and_not_the_raw_session_secret
    client = Object.new
    def client.session_token_secret
      "shopify-session-token-secret"
    end

    derived = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(client)

    refute_equal "shopify-session-token-secret", derived
    assert_equal derived, RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(client)
  end
end
