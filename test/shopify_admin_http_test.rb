# frozen_string_literal: true

require "test_helper"
require "net/http"

class ShopifyAdminHttpTest < Minitest::Test
  POST_URL = "https://demo.myshopify.com/admin/oauth/access_token"
  POST_HEADERS = { "Content-Type" => "application/x-www-form-urlencoded" }.freeze
  POST_BODY = "grant_type=test"

  def test_post_sends_accept_application_json
    captured_request = nil
    response = ok_response("{}")

    Net::HTTP.stub :start, lambda { |*_args, &block|
      http = Object.new
      http.define_singleton_method(:request) do |request|
        captured_request = request
        response
      end
      block.call(http)
    } do
      post_access_token
    end

    assert_equal "application/json", captured_request["Accept"]
  end

  def test_post_surfaces_html_oauth_error_without_json_parser_error
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    response.instance_variable_set(
      :@body,
      "<!DOCTYPE html><html><head><title>400 - Oauth error invalid_request</title></head></html>"
    )
    response.instance_variable_set(:@read, true)

    error = assert_raises(RecordingStudioShopifyPluginTemplate::ShopifyAdminHttpError) do
      stub_post(response) { post_access_token }
    end

    assert_includes error.message, "HTTP 400"
    assert_includes error.message, "invalid_request"
    refute_includes error.message, "DOCTYPE"
  end

  def test_post_surfaces_json_oauth_error_fields
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    response.instance_variable_set(
      :@body,
      { error: "invalid_request", error_description: "Invalid grant_type" }.to_json
    )
    response.instance_variable_set(:@read, true)

    error = assert_raises(RecordingStudioShopifyPluginTemplate::ShopifyAdminHttpError) do
      stub_post(response) { post_access_token }
    end

    assert_equal "HTTP 400: invalid_request - Invalid grant_type", error.message
  end

  private

  def post_access_token
    RecordingStudioShopifyPluginTemplate::ShopifyAdminHttp.post(
      POST_URL,
      body: POST_BODY,
      headers: POST_HEADERS
    )
  end

  def ok_response(body)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def stub_post(response, &)
    Net::HTTP.stub(:start, lambda { |*_args, &block|
      http = Object.new
      http.define_singleton_method(:request) { |_request| response }
      block.call(http)
    }, &)
  end
end
