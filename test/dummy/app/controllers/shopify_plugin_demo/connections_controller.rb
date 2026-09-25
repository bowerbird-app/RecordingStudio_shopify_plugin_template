# frozen_string_literal: true

class ShopifyPluginDemo::ConnectionsController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
    @connected = @install&.connected?
  end

  def create
    shop_domain = resolved_shop_domain
    unless shop_domain
      redirect_to shopify_plugin_demo_connect_path(shopify_embed_query), alert: "Add a shop domain to Connect."
      return
    end

    client = registered_app
    unless client
      redirect_to shopify_plugin_demo_connect_path(shopify_embed_query.merge(shop: shop_domain)),
                  alert: "Add a Registered App before Connect."
      return
    end

    root_recording = current_workspace_root
    unless root_recording
      redirect_to shopify_plugin_demo_connect_path(shopify_embed_query.merge(shop: shop_domain)),
                  alert: "Pick a workspace before Connect."
      return
    end

    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      connected_by: current_user
    )
    unless result.ok?
      redirect_to shopify_plugin_demo_connect_path(shopify_embed_query.merge(shop: shop_domain)), alert: result.error
      return
    end

    host_base_url = RecordingStudioShopifyPluginTemplate.configuration.host_base_url.presence || request.base_url
    ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      session_token: shopify_session_token,
      host_base_url: host_base_url
    )

    query = plugin_settings_return_params(shop_domain).to_query
    redirect_to "#{plugin_settings_path}?#{query}",
                notice: "Connected. Installed is not the same as Connected."
  end

  def destroy
    shop_domain = resolved_shop_domain
    if shop_domain
      RecordingStudioShopifyPluginTemplate::ShopifyInstall.unbind(
        shop_domain: shop_domain,
        client: registered_app
      )
    end
    redirect_to shopify_plugin_demo_connect_path(shopify_embed_query.merge(shop: shop_domain)),
                notice: "Disconnected. The Shopify plugin can still be installed."
  end

  private

  def plugin_settings_return_params(shop_domain)
    shopify_embed_query.merge(shop: shop_domain).compact
  end

  def current_workspace_root
    workspace = Workspace.find_by(name: "Studio Workspace") || Workspace.order(:name).first
    RecordingStudio.root_recording_for(workspace) if workspace
  end
end
