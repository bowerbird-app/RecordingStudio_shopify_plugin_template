# frozen_string_literal: true

module ShopifyPluginDemo
  module InstallContext
    private

    def record_install_from_session_token
      token = params[:shopify_session_token].presence
      return if token.blank?

      client = registered_app
      unless client
        flash.now[:alert] = "Add a Registered App before verifying the session token."
        return
      end

      result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
        token: token,
        client: client,
        expected_shop: @shop_domain
      )
      @shop_domain = result.shop_domain if result.ok?
      flash.now[:alert] = result.error unless result.ok?
    end

    def find_install
      return if @shop_domain.blank?

      RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
        shop_domain: @shop_domain,
        client: registered_app
      )
    end

    def registered_app
      client_id = params[:client_id].presence ||
                  RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id
      return if client_id.blank?

      RecordingStudioOauth::OauthClient.find_by(client_id: client_id)
    end

    def resolved_shop_domain
      RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.normalize_shop(
        params[:shop].presence || params[:shop_domain]
      )
    end
  end
end
