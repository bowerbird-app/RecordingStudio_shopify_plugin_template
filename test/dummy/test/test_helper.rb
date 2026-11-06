# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module ShopifyPluginDemoTestHelpers
  def grant_admin!(user, recording)
    existing = RecordingStudioAccessible.access_recordings_for_actor(
      recording: recording,
      actor: user
    ).first
    return existing if existing

    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
    return result unless result.respond_to?(:failure?) && result.failure?

    manager = manager_actor_on(recording)
    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: user,
      role: :admin,
      manager_actor: manager
    )
    raise result.error if result.respond_to?(:failure?) && result.failure?

    result
  end

  def manager_actor_on(recording)
    RecordingStudio::Recording.where(
      root_recording: recording,
      recordable_type: "RecordingStudio::Access"
    ).filter_map { |access_recording| access_recording.recordable&.actor }.find do |actor|
      actor.is_a?(User) && actor.persisted?
    end
  end
end

class ActiveSupport::TestCase
  include ShopifyPluginDemoTestHelpers
end

class ActionDispatch::IntegrationTest
  include ShopifyPluginDemoTestHelpers
end
