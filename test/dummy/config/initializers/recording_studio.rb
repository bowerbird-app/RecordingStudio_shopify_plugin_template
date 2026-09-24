# frozen_string_literal: true

require Rails.root.join("lib/shopify_plugin_demo/product_config")

RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "AdminRoot",
    "RecordingStudioUser::People",
    "RecordingStudioUser::Profile",
    "RecordingStudioEmbeddable::Embed",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudioAttachable::Attachment",
    "RecordingStudioSiteSettings::SiteSetting",
    "RecordingStudio::Access",
    "RecordingStudioApi::ApiClient",
    "RecordingStudioApi::ApiCredential",
    "RecordingStudioApi::ApiAccessToken",
    "RecordingStudioApi::AdminApi"
  ]

  config.require_recordable_declarations = true

  config.app_name = ShopifyPluginDemo::ProductConfig::NAME if config.respond_to?(:app_name=)

  config.actor = -> { Current.actor }

  config.event_notifications_enabled = true

  config.idempotency_mode = :return_existing

  config.recordable_dup_strategy = :dup
end
