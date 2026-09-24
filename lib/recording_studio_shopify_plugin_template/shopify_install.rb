# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  class ShopifyInstall
    PROVIDER = "shopify"
    Result = Struct.new(:success, :install, :shop_domain, :claims, :client, :error, keyword_init: true) do
      def ok?
        success
      end
    end

    def self.record_from_session_token(token:, client_id: nil, client: nil, expected_shop: nil, secret: nil)
      verified = verified_claims(token: token, client_id: client_id, client: client, secret: secret)
      return verified unless verified.ok?

      parsed = ShopifySessionClaims.from_claims(verified.claims, expected_shop)
      return failure(parsed.error) unless parsed.ok?

      recorded = upsert_install(client: verified.client, shop_domain: parsed.shop_domain)
      recorded.claims = verified.claims if recorded.ok?
      recorded
    end

    def self.find(shop_domain:, client: nil, client_id: nil)
      oauth_client = client || RecordingStudioOauth::OauthClient.find_by(client_id: client_id.to_s)
      domain = ShopifySessionClaims.normalize_shop(shop_domain)
      return if oauth_client.blank? || domain.blank?

      RecordingStudioOauth::ExternalInstall.find_by(
        oauth_client: oauth_client,
        provider: PROVIDER,
        external_id: domain
      )
    end

    def self.bind(shop_domain:, client:, root_recording:, connected_by:)
      domain = ShopifySessionClaims.normalize_shop(shop_domain)
      return failure("shop domain required") if domain.blank? || client.blank?

      upsert_install(client: client, shop_domain: domain, root_recording: root_recording, connected_by: connected_by)
    end

    def self.unbind(shop_domain:, client: nil, client_id: nil)
      install = find(shop_domain: shop_domain, client: client, client_id: client_id)
      return unless install

      install.update!(root_recording: nil, connected_by: nil)
      install
    end

    def self.remove(shop_domain:, client: nil, client_id: nil)
      domain = ShopifySessionClaims.normalize_shop(shop_domain)
      return if domain.blank?

      scope = RecordingStudioOauth::ExternalInstall.where(provider: PROVIDER, external_id: domain)
      scope = scope.where(oauth_client: client) if client
      if client_id.present? && client.blank?
        oauth_client = RecordingStudioOauth::OauthClient.find_by(client_id: client_id.to_s)
        scope = scope.where(oauth_client: oauth_client) if oauth_client
      end
      scope.delete_all
    end

    def self.verified_claims(token:, client_id:, client:, secret:)
      verify = RecordingStudioOauth.verify_session_token(
        token: token, client_id: client_id, client: client, secret: secret
      )
      return failure(verify.error) unless verify.success?

      Result.new(success: true, claims: verify.value.fetch(:claims), client: verify.value.fetch(:client))
    end
    private_class_method :verified_claims

    def self.upsert_install(client:, shop_domain:, root_recording: nil, connected_by: nil)
      recorded = RecordingStudioOauth.record_external_install(
        client: client, provider: PROVIDER, external_id: shop_domain,
        root_recording: root_recording, connected_by: connected_by
      )
      return failure(recorded.error) unless recorded.success?

      Result.new(success: true, install: recorded.value, shop_domain: shop_domain, client: client)
    end
    private_class_method :upsert_install

    def self.failure(message)
      Result.new(success: false, install: nil, shop_domain: nil, claims: nil, client: nil, error: message)
    end
    private_class_method :failure
  end
end
