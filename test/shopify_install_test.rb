# frozen_string_literal: true

require "test_helper"

class ShopifyInstallTest < Minitest::Test
  def test_remove_without_client_does_not_run_and_fails
    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.remove(shop_domain: "demo.myshopify.com")

    refute result.ok?
    assert_equal "client required", result.error
  end
end
