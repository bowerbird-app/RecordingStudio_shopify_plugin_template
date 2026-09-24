# frozen_string_literal: true

require "recording_studio"
require "recording_studio_shopify_plugin_template/version"
require "recording_studio_shopify_plugin_template/engine"
require "recording_studio_shopify_plugin_template/configuration"
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
