# frozen_string_literal: true

class ShopifyPluginDemo::UninstallsController < ActionController::Base
  skip_forgery_protection

  def create
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
end
