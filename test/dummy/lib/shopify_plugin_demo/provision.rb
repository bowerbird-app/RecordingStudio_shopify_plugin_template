# frozen_string_literal: true

module ShopifyPluginDemo
  ProvisionedClient = Data.define(
    :page_recording_id,
    :access_token,
    :oauth_client_id,
    :oauth_client_secret
  ) do
    def bearer_headers
      { "Authorization" => "Bearer #{access_token}" }
    end
  end

  module Provision
    module_function

    def isolated_client!(name: "Shopify plugin demo client")
      actor = User.create!(
        email: "shopify-plugin-demo-#{SecureRandom.hex(8)}@example.com",
        password: "Password1!",
        password_confirmation: "Password1!"
      )
      workspace = Workspace.create!(name: "Shopify plugin demo #{SecureRandom.hex(4)}")
      root_recording = RecordingStudio.root_recording_for(workspace)
      Tree.grant_admin!(root_recording: root_recording, actor: actor)

      page_recording = Tree.record_page!(
        root_recording: root_recording,
        title: "Demo Page #{SecureRandom.hex(3)}",
        actor: actor
      )
      Tree.ensure_embed_on!(page_recording, actor: actor)

      oauth_client_id, oauth_client_secret = issue_named_credentials!(
        access_point_recording: root_recording,
        manager_actor: actor,
        name: name
      )
      access_token = mint_access_token!(
        oauth_client_id: oauth_client_id,
        oauth_client_secret: oauth_client_secret
      )

      ProvisionedClient.new(
        page_recording_id: page_recording.id,
        access_token: access_token,
        oauth_client_id: oauth_client_id,
        oauth_client_secret: oauth_client_secret
      )
    end

    def foreign_page!
      actor = User.create!(
        email: "shopify-plugin-demo-foreign-#{SecureRandom.hex(8)}@example.com",
        password: "Password1!",
        password_confirmation: "Password1!"
      )
      workspace = Workspace.create!(name: "Foreign #{SecureRandom.hex(4)}")
      root_recording = RecordingStudio.root_recording_for(workspace)
      Tree.grant_admin!(root_recording: root_recording, actor: actor)
      page_recording = Tree.record_page!(
        root_recording: root_recording,
        title: "Foreign Page #{SecureRandom.hex(3)}",
        actor: actor
      )
      Tree.ensure_embed_on!(page_recording, actor: actor)
      page_recording
    end

    def issue_named_credentials!(access_point_recording:, manager_actor:, name:)
      result = RecordingStudioApi::Services::ProvisionApiClient.call(
        name: name,
        access_point_recording: access_point_recording,
        manager_actor: manager_actor,
        role: :admin,
        api: Contract::API_KEY
      )
      raise result.error if result.failure?

      payload = result.value
      [payload.fetch(:credential).token_public_id, payload.fetch(:token)]
    end

    def mint_access_token!(oauth_client_id:, oauth_client_secret:)
      result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
        grant_type: Contract::TOKEN_GRANT,
        client_id: oauth_client_id,
        client_secret: oauth_client_secret,
        api: Contract::API_KEY
      )
      raise result.error if result.failure?

      result.value.fetch(:access_token)
    end
    private_class_method :mint_access_token!
  end
end
