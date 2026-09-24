# frozen_string_literal: true

class ShopifyPluginDemo::UninstallsController < ActionController::Base
  skip_forgery_protection

  def create
    unless webhook_signed?
      head :unauthorized
      return
    end

    shop_domain = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.normalize_shop(
      params[:shop] || params.dig(:webhook, :shop_domain) || params.dig(:webhook, :myshopify_domain)
    )
    client_id = RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id
    if shop_domain && client_id.present?
      RecordingStudioShopifyPluginTemplate::ShopifyInstall.remove(
        shop_domain: shop_domain,
        client_id: client_id
      )
    end
    head :ok
  end

  private

  def webhook_signed?
    RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac.valid?(
      raw_body: request.raw_post,
      hmac_header: request.headers[RecordingStudioShopifyPluginTemplate::ShopifyWebhookHmac::HEADER],
      secret: partner_api_secret
    )
  end

  def partner_api_secret
    client_id = RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id
    return if client_id.blank?

    RecordingStudioOauth::OauthClient.find_by(client_id: client_id)&.session_token_secret
  end
end
