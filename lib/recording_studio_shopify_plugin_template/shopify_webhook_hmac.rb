# frozen_string_literal: true

require "base64"
require "openssl"

module RecordingStudioShopifyPluginTemplate
  class ShopifyWebhookHmac
    HEADER = "X-Shopify-Hmac-Sha256"

    def self.valid?(raw_body:, hmac_header:, secret:)
      body = raw_body.to_s
      given = hmac_header.to_s.strip
      key = secret.to_s
      return false if given.blank? || key.blank?

      expected = digest(raw_body: body, secret: key)
      return false if given.bytesize != expected.bytesize

      OpenSSL.fixed_length_secure_compare(given, expected)
    end

    def self.digest(raw_body:, secret:)
      Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret.to_s, raw_body.to_s))
    end
  end
end
