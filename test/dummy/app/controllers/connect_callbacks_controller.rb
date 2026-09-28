# frozen_string_literal: true

class ConnectCallbacksController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    pending = pending_host_oauth_connect
    embed = embed_from_pending(pending)

    if params[:error].present?
      clear_host_oauth_connect
      redirect_to root_path(embed), alert: "Connect was cancelled."
      return
    end

    unless pending && params[:state].to_s == pending["state"].to_s && params[:code].present?
      clear_host_oauth_connect
      redirect_to root_path(embed), alert: "Connect did not finish."
      return
    end

    shop_domain = pending["shop"]
    client = registered_app
    result = RecordingStudioShopifyPluginTemplate::ShopifyOauthConnect.finish(
      code: params[:code],
      client: client,
      shop_domain: shop_domain,
      connected_by: current_user
    )
    unless result.ok?
      clear_host_oauth_connect
      redirect_to root_path(embed.merge(shop: shop_domain).compact), alert: result.error
      return
    end

    host_base_url = ENV["HOST_BASE_URL"].presence || request.base_url
    published = ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: shop_domain,
      client: client,
      root_recording: result.root_recording,
      session_token: session_token_from_pending(pending),
      host_base_url: host_base_url
    )
    settings_url = plugin_settings_path(embed.merge(shop: shop_domain).compact)
    clear_host_oauth_connect
    unless published.ok?
      redirect_to settings_url,
                  alert: "#{ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_FAILED}#{published.error}"
      return
    end

    redirect_to settings_url, notice: ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED
  end

  private

  def embed_from_pending(pending)
    raw = pending&.fetch("embed", nil) || {}
    raw.symbolize_keys.slice(*ShopifyPluginDemo::EmbedQuery::KEYS)
  end

  def session_token_from_pending(pending)
    embed = embed_from_pending(pending)
    embed[:shopify_session_token].presence || embed[:id_token].presence
  end
end
