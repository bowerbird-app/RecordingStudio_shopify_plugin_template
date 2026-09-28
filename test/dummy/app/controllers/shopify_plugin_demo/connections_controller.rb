# frozen_string_literal: true

class ShopifyPluginDemo::ConnectionsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
    if @install&.connected?
      redirect_to plugin_settings_path(shopify_embed_query.merge(shop: @shop_domain).compact)
      return
    end

    start_host_oauth_connect
  end
end
