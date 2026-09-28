# frozen_string_literal: true

class PluginSettingsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  layout "app_home"

  def show
    load_install
    unless @install&.connected?
      start_host_oauth_connect
      return
    end

    @connected = true
  end

  def create
    load_install
    start_host_oauth_connect
  end

  def destroy
    shop_domain = resolved_shop_domain
    if shop_domain
      RecordingStudioShopifyPluginTemplate::ShopifyInstall.unbind(
        shop_domain: shop_domain,
        client: registered_app
      )
    end
    redirect_to plugin_settings_path(shopify_embed_query.merge(shop: shop_domain).compact),
                notice: "Disconnected. The Shopify plugin can still be installed."
  end

  private

  def load_install
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
  end
end
