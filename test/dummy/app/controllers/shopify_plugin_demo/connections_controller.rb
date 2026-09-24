# frozen_string_literal: true

class ShopifyPluginDemo::ConnectionsController < ApplicationController
  def show
    @shop_domain = resolved_shop_domain
    @connection = ShopifyPluginDemo::Connection.for_shop(@shop_domain)
    @connected = @connection&.connected?
  end

  def create
    shop_domain = resolved_shop_domain
    unless shop_domain
      redirect_to shopify_plugin_demo_connect_path, alert: "Add a shop domain to Connect."
      return
    end

    ShopifyPluginDemo::Connection.connect!(shop_domain)
    redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), notice: "Connected. Installed is not the same as Connected."
  end

  def destroy
    shop_domain = resolved_shop_domain
    ShopifyPluginDemo::Connection.disconnect!(shop_domain) if shop_domain
    redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), notice: "Disconnected. The Shopify plugin can still be installed."
  end

  private

  def resolved_shop_domain
    ShopifyPluginDemo::Connection.normalize_shop_domain(params[:shop].presence || params[:shop_domain])
  end
end
