# frozen_string_literal: true

class PluginSettingsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
    unless @install&.connected?
      redirect_to shopify_plugin_demo_connect_path(connect_redirect_params)
      return
    end

    @connected = true
  end

  private

  def connect_redirect_params
    shopify_embed_query.merge(shop: @shop_domain).compact
  end
end
