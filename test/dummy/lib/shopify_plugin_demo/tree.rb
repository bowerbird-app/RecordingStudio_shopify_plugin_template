# frozen_string_literal: true

module ShopifyPluginDemo
  module Tree
    module_function

    def record_page!(root_recording:, title:, actor:)
      page = Page.create!(title: title)
      RecordingStudio.record!(
        action: "created",
        recordable: page,
        root_recording: root_recording,
        parent_recording: root_recording,
        actor: actor
      ).recording
    end

    def grant_admin!(root_recording:, actor:)
      existing = RecordingStudioAccessible.access_recordings_for_actor(
        recording: root_recording,
        actor: actor
      ).first
      return existing if existing

      result = RecordingStudioAccessible.bootstrap_owner_access!(
        recording: root_recording,
        actor: actor
      )
      raise result.error if result.failure?

      result.value
    end

    def ensure_embed_on!(page_recording, actor:)
      page_recording.ensure_embed!(enabled: true, actor: actor)
    end
  end
end
