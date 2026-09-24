# frozen_string_literal: true

class ShopifyPluginDemo::ConnectionsController < ApplicationController
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

    redirect_to shopify_plugin_demo_connect_path(shop: shop_domain), notice: "Connected. Installed is not the same as Connected."
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

  def record_install_from_session_token
    token = params[:shopify_session_token].presence
    return if token.blank?

    client = registered_app
    unless client
      flash.now[:alert] = "Add a Registered App before verifying the session token."
      return
    end

    result = RecordingStudioShopifyPluginTemplate::ShopifyInstall.record_from_session_token(
      token: token,
      client: client,
      expected_shop: @shop_domain
    )
    @shop_domain = result.shop_domain if result.ok?
    flash.now[:alert] = result.error unless result.ok?
  end

  def find_install
    return if @shop_domain.blank?

    RecordingStudioShopifyPluginTemplate::ShopifyInstall.find(
      shop_domain: @shop_domain,
      client: registered_app
    )
  end

  def registered_app
    client_id = params[:client_id].presence ||
                RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id
    return if client_id.blank?

    RecordingStudioOauth::OauthClient.find_by(client_id: client_id)
  end

  def current_workspace_root
    workspace = Workspace.find_by(name: "Studio Workspace") || Workspace.order(:name).first
    RecordingStudio.root_recording_for(workspace) if workspace
  end

  def resolved_shop_domain
    RecordingStudioShopifyPluginTemplate::ShopifySessionClaims.normalize_shop(
      params[:shop].presence || params[:shop_domain]
    )
  end
end
