# frozen_string_literal: true

module ShopifyPluginDemo
  module HostOauthConnect
    SESSION_KEY = :host_oauth_connect

    private

    def start_host_oauth_connect
      client = registered_app
      unless client
        redirect_to root_path(shopify_embed_query), alert: "Add a Registered App before Connect."
        return
      end

      verifier = oauth_code_verifier
      state = SecureRandom.urlsafe_base64(16)
      session[SESSION_KEY] = {
        "verifier" => verifier,
        "state" => state,
        "shop" => resolved_shop_domain,
        "embed" => shopify_embed_query.stringify_keys
      }
      ensure_callback_redirect_uri!(client)

      redirect_to recording_studio_oauth.oauth_authorize_path(
        response_type: "code",
        client_id: client.client_id,
        redirect_uri: connect_callback_url,
        state: state,
        code_challenge: RecordingStudioOauth::Pkce.s256_challenge(verifier),
        code_challenge_method: RecordingStudioOauth::Pkce::S256
      )
    end

    def pending_host_oauth_connect
      session[SESSION_KEY]
    end

    def clear_host_oauth_connect
      session.delete(SESSION_KEY)
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
  end
end
