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

  # Hosts must set authorize_write before Recording Studio core 6.5.0.
  # Writes fail closed: missing authorize_write raises AuthorizationError;
  # missing actor raises ActorRequired. `actor.present?` is not a write policy.
  # Access grant/bootstrap writes go through Accessible's AccessCreationContext
  # (same path as grant_access / bootstrap_owner_access!), not a logged-in check.
  config.authorize_write = lambda { |actor:, root_recording:, recordable:, **|
    write_actor = if actor.is_a?(User) && actor.persisted?
      actor
    elsif Current.actor.is_a?(User) && Current.actor.persisted?
      Current.actor
    end
    next false unless write_actor
    next false unless root_recording

    if defined?(RecordingStudio::Access) && recordable.is_a?(RecordingStudio::Access)
      next true if RecordingStudioAccessible::AccessCreationContext.allowed?

      RecordingStudioAccessible.authorized?(
        actor: write_actor,
        recording: root_recording,
        role: :admin
      )
    else
      RecordingStudioAccessible.authorized?(
        actor: write_actor,
        recording: root_recording,
        role: :edit
      )
    end
  }

  config.event_notifications_enabled = true

  config.idempotency_mode = :return_existing

  config.recordable_dup_strategy = :dup
end
