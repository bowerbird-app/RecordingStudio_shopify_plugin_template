# frozen_string_literal: true

module ShopifyPluginDemo
  module HostOauthConnect
    SESSION_KEY = :host_oauth_connect
    BindOutcome = Data.define(:ok, :root_recording, :error) do
      def ok?
        ok
      end
    end

    private

    def start_host_oauth_connect
      client = registered_app
      unless client
        redirect_to root_path(shopify_embed_query), alert: "Add a Registered App before Connect."
        return
      end

      store_pending_oauth!(client)
      redirect_to recording_studio_oauth.oauth_authorize_path(authorize_query(client))
    end

    def bind_after_oauth(code:, client:, shop_domain:, connected_by:)
      authorization = oauth_authorization_for(code, client)
      return bind_failure("Connect did not finish.") if authorization.blank?

      root_recording = oauth_workspace_root(authorization)
      return bind_failure("Pick a workspace before Connect.") if root_recording.blank?

      bind_shop(
        shop_domain: shop_domain,
        client: client,
        root_recording: root_recording,
        connected_by: connected_by
      )
    end

    def pending_host_oauth_connect
      session[SESSION_KEY]
    end

    def clear_host_oauth_connect
      session.delete(SESSION_KEY)
    end

    def store_pending_oauth!(client)
      session[SESSION_KEY] = {
        "verifier" => oauth_code_verifier,
        "state" => SecureRandom.urlsafe_base64(16),
        "shop" => resolved_shop_domain,
        "embed" => shopify_embed_query.stringify_keys
      }
      ensure_callback_redirect_uri!(client)
    end

    def authorize_query(client)
      pending = pending_host_oauth_connect
      {
        response_type: "code",
        client_id: client.client_id,
        redirect_uri: connect_callback_url,
        state: pending.fetch("state"),
        code_challenge: RecordingStudioOauth::Pkce.s256_challenge(pending.fetch("verifier")),
        code_challenge_method: RecordingStudioOauth::Pkce::S256
      }
    end

    def oauth_code_verifier
      loop do
        verifier = SecureRandom.urlsafe_base64(32)
        return verifier if RecordingStudioOauth::Pkce.valid_verifier?(verifier)
      end
    end

    def ensure_callback_redirect_uri!(client)
      uri = connect_callback_url
      return if client.redirect_uri_allowed?(uri)

      client.redirect_uris = Array(client.redirect_uris) + [uri]
      client.save!
    end

    def oauth_authorization_for(code, client)
      return if client.blank? || code.blank?

      record = RecordingStudioOauth::AuthorizationCode.find_by_token(
        RecordingStudioOauth::OauthAuthorizationCode,
        code
      )
      authorization = record&.oauth_authorization
      return if authorization.blank? || authorization.oauth_client_id != client.id
      return if authorization.revoked?

      authorization
    end

    def oauth_workspace_root(authorization)
      parent = authorization.manager_access_recording&.parent_recording
      parent&.root_recording || parent
    end

    def bind_shop(shop_domain:, client:, root_recording:, connected_by:)
      bind = RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
        shop_domain: shop_domain,
        client: client,
        root_recording: root_recording,
        connected_by: connected_by
      )
      return bind_failure(bind.error) unless bind.ok?

      BindOutcome.new(ok: true, root_recording: root_recording, error: nil)
    end

    def bind_failure(message)
      BindOutcome.new(ok: false, root_recording: nil, error: message)
    end
  end
end
