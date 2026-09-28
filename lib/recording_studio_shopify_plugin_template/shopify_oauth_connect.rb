# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  class ShopifyOauthConnect
    Result = Struct.new(:success, :install, :shop_domain, :client, :root_recording, :error, keyword_init: true) do
      def ok?
        success
      end
    end

    def self.finish(code:, client:, shop_domain:, connected_by:)
      authorization = authorization_for(code: code, client: client)
      return failure("Connect did not finish.") if authorization.blank?

      root_recording = workspace_root_for(authorization)
      return failure("Pick a workspace before Connect.") if root_recording.blank?

      bind = ShopifyInstall.bind(
        shop_domain: shop_domain,
        client: client,
        root_recording: root_recording,
        connected_by: connected_by
      )
      return failure(bind.error) unless bind.ok?

      Result.new(
        success: true,
        install: bind.install,
        shop_domain: bind.shop_domain,
        client: client,
        root_recording: root_recording
      )
    end

    def self.workspace_root_for(authorization)
      parent = authorization.manager_access_recording&.parent_recording
      parent&.root_recording || parent
    end

    def self.authorization_for(code:, client:)
      return if client.blank? || code.blank?

      record = RecordingStudioOauth::AuthorizationCode.find_by_token(
        RecordingStudioOauth::OauthAuthorizationCode,
        code
      )
      authorization = record&.oauth_authorization
      return if authorization.blank?
      return if authorization.oauth_client_id != client.id
      return if authorization.revoked?

      authorization
    end
    private_class_method :authorization_for

    def self.failure(message)
      Result.new(success: false, error: message)
    end
    private_class_method :failure
  end
end
