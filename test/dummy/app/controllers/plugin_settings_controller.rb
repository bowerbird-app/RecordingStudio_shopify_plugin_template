# frozen_string_literal: true

class PluginSettingsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  layout "app_home"

  def show
    load_install
    @connected = @install&.connected?
  end

  def create
    shop_domain = resolved_shop_domain
    unless shop_domain
      redirect_to settings_path, alert: "Add a shop domain to Connect."
      return
    end

    client = registered_app
    unless client
      redirect_to settings_path(shop_domain), alert: "Add a Registered App before Connect."
      return
    end

    root_recording = current_workspace_root
    unless root_recording
      redirect_to settings_path(shop_domain), alert: "Pick a workspace before Connect."
      return
    end

    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      connected_by: current_user
    )
    unless result.ok?
      redirect_to settings_path(shop_domain), alert: result.error
      return
    end

    host_base_url = ENV["HOST_BASE_URL"].presence || request.base_url
    published = ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      session_token: shopify_session_token,
      host_base_url: host_base_url
    )
    unless published.ok?
      redirect_to settings_path(shop_domain),
                  alert: "#{ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_FAILED}#{published.error}"
      return
    end

    redirect_to settings_path(shop_domain),
                notice: ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED
  end

  def destroy
    shop_domain = resolved_shop_domain
    if shop_domain
      RecordingStudioShopifyPluginTemplate::ShopifyInstall.unbind(
        shop_domain: shop_domain,
        client: registered_app
      )
    end
    redirect_to settings_path(shop_domain),
                notice: "Disconnected. The Shopify plugin can still be installed."
  end

  private

  def load_install
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
  end

  def settings_path(shop_domain = resolved_shop_domain)
    plugin_settings_path(shopify_embed_query.merge(shop: shop_domain).compact)
  end

  def current_workspace_root
    workspace = Workspace.find_by(name: "Studio Workspace") || Workspace.order(:name).first
    RecordingStudio.root_recording_for(workspace) if workspace
  end
end
