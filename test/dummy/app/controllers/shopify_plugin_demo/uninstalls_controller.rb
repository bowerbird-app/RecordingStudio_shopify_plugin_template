# frozen_string_literal: true

class ShopifyPluginDemo::UninstallsController < ActionController::Base
  skip_forgery_protection

  def create
    shop_domain = ShopifyPluginDemo::Connection.normalize_shop_domain(
      params[:shop] || params.dig(:webhook, :shop_domain) || params.dig(:webhook, :myshopify_domain)
    )
    ShopifyPluginDemo::Connection.disconnect!(shop_domain) if shop_domain
    head :ok
  end
end
