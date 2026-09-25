# frozen_string_literal: true

require "test_helper"

class EmbeddedIframeSessionCookiesTest < ActionDispatch::IntegrationTest
  test "same site protection is lax on http and none on https" do
    protection = Rails.application.config.action_dispatch.cookies_same_site_protection

    http_request = build_request(ssl: false)
    https_request = build_request(ssl: true)

    assert_equal :lax, protection.call(http_request)
    assert_equal :none, protection.call(https_request)
  end

  test "session store sets secure on https responses" do
    store = session_cookie_store
    request = build_request(ssl: true)
    cookie = { value: "probe" }

    store.send(:set_cookie, request, nil, cookie)

    assert cookie[:secure]
  end

  test "session store omits secure on http responses" do
    store = session_cookie_store
    request = build_request(ssl: false)
    cookie = { value: "probe" }

    store.send(:set_cookie, request, nil, cookie)

    refute cookie[:secure]
  end

  private

    def build_request(ssl:)
      ActionDispatch::TestRequest.create.tap do |request|
        request.env["HTTPS"] = "on" if ssl
      end
    end

    def session_cookie_store
      Rails.application.middleware.find do |middleware|
        middleware.klass == ShopifyPluginDemo::EmbeddedIframeSessionCookieStore
      end.klass.new(->(_env) { [200, {}, []] })
    end
end
