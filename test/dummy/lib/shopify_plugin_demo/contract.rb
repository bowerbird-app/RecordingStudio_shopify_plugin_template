# frozen_string_literal: true

require_relative "product_config"

module ShopifyPluginDemo
  module Contract
    API_KEY = :shopify_plugin_demo
    OPENAPI_TITLE = ShopifyPluginDemo::ProductConfig::NAME
    ENGINE_MOUNT = "/recording_studio_api"
    API_VERSION = "v1"
    RESOURCE = "pages"
    ACTIONS_EMBED = "actions/embed"
    SHORT_EMBED = "embed"
    TOKEN_GRANT = "client_credentials"

    PUBLIC_RESOURCE_PREFIX = "#{ENGINE_MOUNT}/api/#{API_VERSION}".freeze
    NAMED_PREFIX = "#{ENGINE_MOUNT}/apis/#{API_KEY}".freeze
    NAMED_RESOURCE_PREFIX = "#{NAMED_PREFIX}/#{API_VERSION}".freeze
    TOKEN_PATH = "#{NAMED_PREFIX}/oauth/token".freeze
    AUTHORIZE_PATH = "/recording_studio_oauth/oauth/authorize"
    CONNECT_PATH = "/shopify_plugin_demo/connect"
    RELAY_CALLBACK_PATH = "/recording_studio_oauth/callback"
    CONNECT_TOKEN_PATH = TOKEN_PATH
    UNINSTALL_PATH = "/shopify_plugin_demo/uninstall"

    SCHEMA_VERSION = 1
    REQUIRED_TOP_KEYS = %w[schema_version html configuration sdk].freeze
    CONFIGURATION_KEYS = %w[theme sizing].freeze
    HANDLER = "RecordingStudioEmbeddable::Api::EmbedRecording"

    BOOT_CONFIG_API = "config.api ShopifyPluginDemo::Contract::API_KEY"
    BOOT_DEFAULT_RESOURCE_ACTIONS = "register_default_resource_actions!(api: ShopifyPluginDemo::Contract::API_KEY)"
    BOOT_EMBED_CAPABILITY_ACTION = "RecordingStudioEmbeddable::Api.register_capability_action!"
    FORBIDDEN_HOST_EMBED_REGISTER = /register_capability_action\(\s*:embed\b/

    BrowserPayloadV1 = Data.define(
      :schema_version,
      :html,
      :theme,
      :sizing,
      :sdk_minimum_version
    )

    SoftRegisterOrder = Data.define(
      :config_api_at,
      :default_resource_actions_at,
      :embed_capability_action_at
    ) do
      def valid?
        [config_api_at, default_resource_actions_at, embed_capability_action_at].all? &&
          config_api_at < default_resource_actions_at &&
          config_api_at < embed_capability_action_at
      end
    end

    module_function

    def actions_embed_path(page_recording_id)
      "#{NAMED_RESOURCE_PREFIX}/#{RESOURCE}/#{page_recording_id}/#{ACTIONS_EMBED}"
    end

    def short_embed_path(page_recording_id)
      "#{NAMED_RESOURCE_PREFIX}/#{RESOURCE}/#{page_recording_id}/#{SHORT_EMBED}"
    end

    def public_actions_embed_path(page_recording_id)
      "#{PUBLIC_RESOURCE_PREFIX}/#{RESOURCE}/#{page_recording_id}/#{ACTIONS_EMBED}"
    end

    def parse_browser_payload!(body)
      missing = REQUIRED_TOP_KEYS - body.keys.map(&:to_s)
      raise ArgumentError, "BrowserPayload missing keys: #{missing.join(', ')}" if missing.any?

      configuration = body.fetch("configuration")
      missing_config = CONFIGURATION_KEYS - configuration.keys.map(&:to_s)
      raise ArgumentError, "configuration missing keys: #{missing_config.join(', ')}" if missing_config.any?

      schema_version = body.fetch("schema_version")
      raise ArgumentError, "schema_version must be #{SCHEMA_VERSION}" unless schema_version == SCHEMA_VERSION

      sdk = body.fetch("sdk")
      expected_sdk = if defined?(RecordingStudioEmbeddable::BrowserPayload::SDK_MINIMUM_VERSION)
                       RecordingStudioEmbeddable::BrowserPayload::SDK_MINIMUM_VERSION
                     end
      minimum_version = sdk.fetch("minimum_version")
      if expected_sdk && minimum_version != expected_sdk
        raise ArgumentError, "sdk.minimum_version must be #{expected_sdk}"
      end

      BrowserPayloadV1.new(
        schema_version: schema_version,
        html: body.fetch("html"),
        theme: configuration.fetch("theme"),
        sizing: configuration.fetch("sizing"),
        sdk_minimum_version: minimum_version
      )
    end

    def parse_soft_register_order!(initializer_source)
      raise ArgumentError, "host must not register :embed" if initializer_source.match?(FORBIDDEN_HOST_EMBED_REGISTER)

      SoftRegisterOrder.new(
        config_api_at: index!(initializer_source, BOOT_CONFIG_API),
        default_resource_actions_at: index!(initializer_source, BOOT_DEFAULT_RESOURCE_ACTIONS),
        embed_capability_action_at: index!(initializer_source, BOOT_EMBED_CAPABILITY_ACTION)
      )
    end

    def assert_gem_owned_embed_handler!(api: API_KEY)
      action = RecordingStudioApi.capability_action(:embed, api: api)
      raise ArgumentError, "named API #{api.inspect} has no :embed action" if action.nil?

      handler_name = action.handler.to_s
      return if handler_name == HANDLER

      raise ArgumentError, "expected #{HANDLER}, got #{handler_name}"
    end

    def index!(source, token)
      index = source.index(token)
      raise ArgumentError, "missing boot token #{token.inspect}" if index.nil?

      index
    end
    private_class_method :index!
  end
end
