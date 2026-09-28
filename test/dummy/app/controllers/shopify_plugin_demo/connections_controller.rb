# frozen_string_literal: true

class ShopifyPluginDemo::ConnectionsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    redirect_to plugin_settings_path(shopify_embed_query.merge(shop: resolved_shop_domain).compact)
  end
end
