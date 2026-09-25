# frozen_string_literal: true

require Rails.root.join("lib/shopify_plugin_demo/embedded_iframe_session_cookies")

Rails.application.config.action_dispatch.cookies_same_site_protection = lambda { |request|
  if ShopifyPluginDemo::EmbeddedIframeSessionCookies.cross_site_session?(request)
    :none
  else
    :lax
  end
}

Rails.application.config.session_store(
  ShopifyPluginDemo::EmbeddedIframeSessionCookieStore,
  key: "_dummy_session"
)
