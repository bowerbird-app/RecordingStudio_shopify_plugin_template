# frozen_string_literal: true

module ShopifyPluginDemo
  # App Home iframes the dummy host from admin.shopify.com (cross-site). Session
  # cookies need SameSite=None with Secure on HTTPS so Connect sign-in persists.
  module EmbeddedIframeSessionCookies
    module_function

    def cross_site_session?(request)
      request.ssl? || Rails.application.config.force_ssl
    end
  end

  class EmbeddedIframeSessionCookieStore < ActionDispatch::Session::CookieStore
    private

      def set_cookie(request, _response, cookie)
        cookie[:secure] = true if EmbeddedIframeSessionCookies.cross_site_session?(request)
        super
      end
  end
end
