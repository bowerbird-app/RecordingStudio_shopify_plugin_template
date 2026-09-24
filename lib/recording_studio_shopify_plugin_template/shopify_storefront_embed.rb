# frozen_string_literal: true

require "base64"
require "openssl"

module RecordingStudioShopifyPluginTemplate
  class ShopifyStorefrontEmbed
    PURPOSE = "shopify-storefront-embed-v1"
    SEPARATOR = "|"

    Result = Struct.new(:success, :shop_domain, :page_recording_id, :install, :error, keyword_init: true) do
      def ok?
        success
      end
    end

    def self.secret_for(client)
      raw = client&.session_token_secret
      return if raw.blank?

      OpenSSL::HMAC.hexdigest("SHA256", raw, PURPOSE)
    end

    def self.mint(shop_domain:, page_recording_id:, secret:)
      shop = ShopifySessionClaims.normalize_shop(shop_domain)
      page_id = page_recording_id.to_s.strip
      return if shop.blank? || page_id.blank? || secret.to_s.strip.blank?

      mac = signature(shop, page_id, secret)
      Base64.urlsafe_encode64([shop, page_id, mac].join(SEPARATOR), padding: false)
    end

    def self.authorize(token:, shop_domain:, client:, page_recording:)
      parsed = parse(token, secret: secret_for(client))
      return parsed unless parsed.ok?

      bind_connected_page(parsed, shop_domain: shop_domain, client: client, page_recording: page_recording)
    end

    def self.parse(token, secret:)
      shop, page_id, mac = token_fields(token)
      return failure("token required") if secret.to_s.strip.blank?
      return failure("token invalid") if shop.blank? || page_id.blank? || mac.blank?
      return failure("token invalid") unless secure_compare(mac, signature(shop, page_id, secret))

      Result.new(success: true, shop_domain: shop, page_recording_id: page_id, install: nil, error: nil)
    rescue ArgumentError
      failure("token invalid")
    end

    def self.bind_connected_page(parsed, shop_domain:, client:, page_recording:)
      mismatch = request_mismatch(parsed, shop_domain, page_recording)
      return mismatch if mismatch

      install = connected_install(parsed.shop_domain, client)
      return failure("not connected") unless install
      return failure("wrong shop") unless page_on_connected_root?(page_recording, install)

      Result.new(success: true, shop_domain: parsed.shop_domain, page_recording_id: parsed.page_recording_id,
                 install: install, error: nil)
    end
    private_class_method :bind_connected_page

    def self.request_mismatch(parsed, shop_domain, page_recording)
      expected_shop = ShopifySessionClaims.normalize_shop(shop_domain)
      return failure("shop does not match") if expected_shop.blank? || expected_shop != parsed.shop_domain
      return failure("page does not match") unless page_matches_token?(page_recording, parsed)

      nil
    end
    private_class_method :request_mismatch

    def self.connected_install(shop_domain, client)
      install = ShopifyInstall.find(shop_domain: shop_domain, client: client)
      return if install.blank? || !install.connected?

      install
    end
    private_class_method :connected_install

    def self.token_fields(token)
      return [nil, nil, nil] if token.to_s.strip.blank?

      decoded = Base64.urlsafe_decode64(token.to_s)
      shop, page_id, mac = decoded.split(SEPARATOR, 3)
      [ShopifySessionClaims.normalize_shop(shop), page_id.to_s.strip, mac]
    end
    private_class_method :token_fields

    def self.page_matches_token?(page_recording, parsed)
      page_recording.present? && page_recording.id.to_s == parsed.page_recording_id
    end
    private_class_method :page_matches_token?

    def self.page_on_connected_root?(page_recording, install)
      root_id = page_recording.root_recording_id.presence || page_recording.id
      root_id.to_s == install.root_recording_id.to_s
    end
    private_class_method :page_on_connected_root?

    def self.signature(shop, page_id, secret)
      OpenSSL::HMAC.hexdigest("SHA256", secret, [shop, page_id].join(SEPARATOR))
    end
    private_class_method :signature

    def self.secure_compare(left, right)
      return false if left.bytesize != right.bytesize

      OpenSSL.fixed_length_secure_compare(left, right)
    end
    private_class_method :secure_compare

    def self.failure(message)
      Result.new(success: false, shop_domain: nil, page_recording_id: nil, install: nil, error: message)
    end
    private_class_method :failure
  end
end
