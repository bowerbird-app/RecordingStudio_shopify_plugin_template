# frozen_string_literal: true

require "recording_studio"
require "recording_studio_oauth"
require "recording_studio_shopify_plugin_template/version"
require "recording_studio_shopify_plugin_template/engine"
require "recording_studio_shopify_plugin_template/configuration"
require "recording_studio_shopify_plugin_template/shopify_session_claims"
require "recording_studio_shopify_plugin_template/shopify_install"
require "recording_studio_shopify_plugin_template/shopify_storefront_embed"
require "recording_studio_shopify_plugin_template/shopify_admin_http"
require "recording_studio_shopify_plugin_template/shopify_shop_metafield_payload"
require "recording_studio_shopify_plugin_template/shopify_shop_metafield_definitions"
require "recording_studio_shopify_plugin_template/shopify_shop_metafield_sync"
require "recording_studio_shopify_plugin_template/shopify_shop_metafields"
require "recording_studio_shopify_plugin_template/shopify_webhook_hmac"
require "recording_studio_shopify_plugin_template/capabilities/example"

module RecordingStudioShopifyPluginTemplate
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
