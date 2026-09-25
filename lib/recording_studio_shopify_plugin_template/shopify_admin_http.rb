# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module RecordingStudioShopifyPluginTemplate
  module ShopifyAdminHttp
    module_function

    def post(url, body:, headers:)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request.body = body
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
      JSON.parse(response.body.to_s.presence || "{}")
    end
  end
end
