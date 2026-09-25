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
      redirect_to shopify_plugin_demo_connect_path, alert: "Add a shop domain to Connect."
      return
    end

    client = registered_app
    unless client
      redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), alert: "Add a Registered App before Connect."
      return
    end

    root_recording = current_workspace_root
    unless root_recording
      redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), alert: "Pick a workspace before Connect."
      return
    end

    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.bind(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      connected_by: current_user
    )
    unless result.ok?
      redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), alert: result.error
      return
    end

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
    redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), notice: "Disconnected. The Shopify plugin can still be installed."
  end

  private

  def plugin_settings_return_params(shop_domain)
    permitted = params.permit(:host, :hmac, :id_token, :embedded, :shopify_session_token, :client_id)
    permitted.to_h.symbolize_keys.merge(shop: shop_domain).compact_blank
  end

  def current_workspace_root
    workspace = Workspace.find_by(name: "Studio Workspace") || Workspace.order(:name).first
    RecordingStudio.root_recording_for(workspace) if workspace
  end
end
