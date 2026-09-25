# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  class Configuration
    attr_accessor :api_key, :enable_feature_x, :timeout, :registered_app_client_id, :host_base_url
    attr_reader :hooks

    def initialize
      @api_key = ENV.fetch("RECORDING_STUDIO_SHOPIFY_PLUGIN_TEMPLATE_API_KEY", nil)
      @enable_feature_x = false
      @timeout = 5
      @registered_app_client_id = ENV.fetch("SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID", nil)
      @host_base_url = ENV.fetch("HOST_BASE_URL", nil)
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        api_key: api_key,
        enable_feature_x: enable_feature_x,
        timeout: timeout,
        registered_app_client_id: registered_app_client_id,
        host_base_url: host_base_url,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
