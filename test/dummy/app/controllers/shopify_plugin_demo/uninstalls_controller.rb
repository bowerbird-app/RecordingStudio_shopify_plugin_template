# frozen_string_literal: true

class ShopifyPluginDemo::UninstallsController < ActionController::Base
  skip_forgery_protection

  def create
    shop_domain = RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.normalize_shop(
      params[:shop] || params.dig(:webhook, :shop_domain) || params.dig(:webhook, :myshopify_domain)
    )
    RecordingStudioShopifyPluginTemplate::ShopifyInstall.remove(shop_domain: shop_domain) if shop_domain
    head :ok
  end
end
