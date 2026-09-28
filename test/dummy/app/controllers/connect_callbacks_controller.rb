# frozen_string_literal: true

class ConnectCallbacksController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def show
    pending = pending_host_oauth_connect
    embed = embed_from_pending(pending)

    if params[:error].present? || !valid_oauth_return?(pending)
      clear_host_oauth_connect
      redirect_to root_path(embed), alert: oauth_return_alert
      return
    end

    finish_oauth_bind_and_settings(pending, embed)
  end

  private

  def finish_oauth_bind_and_settings(pending, embed)
    shop_domain = pending["shop"]
    client = registered_app
    result = bind_after_oauth(
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

    publish_metafields_and_redirect(pending, embed, shop_domain, client, result.root_recording)
  end

  def publish_metafields_and_settings_notice(published)
    return ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_SYNCED if published.ok?

    "#{ShopifyPluginDemo::ProductConfig::STOREFRONT_METAFIELDS_FAILED}#{published.error}"
  end

  def publish_metafields_and_redirect(pending, embed, shop_domain, client, root_recording)
    published = ShopifyPluginDemo::PublishStorefrontMetafields.call(
      shop_domain: shop_domain,
      client: client,
      root_recording: root_recording,
      session_token: session_token_from_pending(pending),
      host_base_url: ENV["HOST_BASE_URL"].presence || request.base_url
    )
    settings_url = plugin_settings_path(embed.merge(shop: shop_domain).compact)
    clear_host_oauth_connect
    flash_key = published.ok? ? :notice : :alert
    redirect_to settings_url, flash_key => publish_metafields_and_settings_notice(published)
  end

  def valid_oauth_return?(pending)
    pending.present? && params[:error].blank? &&
      params[:state].to_s == pending["state"].to_s && params[:code].present?
  end

  def oauth_return_alert
    params[:error].present? ? "Connect was cancelled." : "Connect did not finish."
  end

  def embed_from_pending(pending)
    raw = pending&.fetch("embed", nil) || {}
    raw.symbolize_keys.slice(*ShopifyPluginDemo::EmbedQuery::KEYS)
  end

  def session_token_from_pending(pending)
    embed = embed_from_pending(pending)
    embed[:shopify_session_token].presence || embed[:id_token].presence
  end
end
