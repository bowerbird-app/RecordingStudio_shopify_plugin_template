# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module RecordingStudioShopifyPluginTemplate
  class ShopifyAdminHttpError < StandardError; end

  module ShopifyAdminHttp
    module_function

    def post(url, body:, headers:)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request_headers(headers).each { |key, value| request[key] = value }
      request.body = body
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
      parse_json_response(response)
    end

    def request_headers(headers)
      headers.transform_keys(&:to_s).tap do |merged|
        merged["Accept"] = "application/json" unless merged.key?("Accept")
      end
    end
    private_class_method :request_headers

    def parse_json_response(response)
      status = response.code.to_i
      raw_body = response.body.to_s
      unless response.is_a?(Net::HTTPSuccess)
        raise ShopifyAdminHttpError, response_error_message(status, raw_body)
      end
      return {} if raw_body.blank?

      JSON.parse(raw_body)
    rescue JSON::ParserError
      raise ShopifyAdminHttpError, response_error_message(status, raw_body)
    end
    private_class_method :parse_json_response

    def response_error_message(status, raw_body)
      json = JSON.parse(raw_body)
      parts = [json["error"], json["error_description"]].compact
      return "HTTP #{status}: #{parts.join(' - ')}" if parts.any?
    rescue JSON::ParserError
      title = raw_body[%r{<title>(.*?)</title>}im, 1]&.strip
      return "HTTP #{status}: #{title}" if title.present?

      snippet = raw_body.strip
      snippet = snippet[0, 120] if snippet.length > 120
      "HTTP #{status}: #{snippet.presence || 'empty response'}"
    end
    private_class_method :response_error_message
  end
end
