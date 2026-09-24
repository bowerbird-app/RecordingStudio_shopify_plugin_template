# frozen_string_literal: true

require "test_helper"

class ShopifySessionClaimsTest < Minitest::Test
  def test_parses_shop_from_dest
    result = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.from_claims(
      "dest" => "https://demo.myshopify.com",
      "iss" => "https://demo.myshopify.com/admin"
    )

    assert result.ok?
    assert_equal "demo.myshopify.com", result.shop_domain
  end

  def test_parses_shop_from_iss_when_dest_missing
    result = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.from_claims(
      "iss" => "https://demo.myshopify.com/admin"
    )

    assert result.ok?
    assert_equal "demo.myshopify.com", result.shop_domain
  end

  def test_fails_when_dest_and_iss_shops_differ
    result = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.from_claims(
      "dest" => "https://demo.myshopify.com",
      "iss" => "https://other.myshopify.com/admin"
    )

    refute result.ok?
    assert_equal "shop claims do not match", result.error
  end

  def test_fails_when_expected_shop_does_not_match_claims
    result = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.from_claims(
      { "dest" => "https://demo.myshopify.com" },
      "other.myshopify.com"
    )

    refute result.ok?
    assert_equal "shop does not match", result.error
  end

  def test_fails_when_shop_claims_missing
    result = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.from_claims("aud" => "partner-app")

    refute result.ok?
    assert_equal "shop claim missing", result.error
  end
end
