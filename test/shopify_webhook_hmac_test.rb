# frozen_string_literal: true

require "test_helper"

class ShopifyWebhookHmacTest < Minitest::Test
  SECRET = "partner-api-secret"
  BODY = '{"myshopify_domain":"demo.myshopify.com"}'
  HEADER = "kdfJApThHiCzjL8rbQEgeCof9DJTZR0CZp5bKHet3Lg="

  def test_valid_hmac_matches_shopify_base64_sha256
    assert_equal HEADER, RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.digest(
      raw_body: BODY,
      secret: SECRET
    )
    assert RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: BODY,
      hmac_header: HEADER,
      secret: SECRET
    )
  end

  def test_wrong_secret_is_rejected
    refute RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: BODY,
      hmac_header: HEADER,
      secret: "other-secret"
    )
  end

  def test_tampered_body_is_rejected
    refute RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: '{"myshopify_domain":"other.myshopify.com"}',
      hmac_header: HEADER,
      secret: SECRET
    )
  end

  def test_missing_header_is_rejected
    refute RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: BODY,
      hmac_header: nil,
      secret: SECRET
    )
  end

  def test_blank_secret_is_rejected
    refute RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: BODY,
      hmac_header: HEADER,
      secret: ""
    )
  end
end
