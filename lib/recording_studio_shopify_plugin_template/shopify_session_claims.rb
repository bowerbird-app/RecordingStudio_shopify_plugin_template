# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  class ShopifySessionClaims
    Result = Struct.new(:success, :shop_domain, :error, keyword_init: true) do
      def ok?
        success
      end
    end

    def self.from_claims(claims, expected_shop = nil)
      shop_domain = shop_from_claim_hash(stringify_keys(claims))
      return shop_domain if shop_domain.is_a?(Result)

      expected = normalize_shop(expected_shop)
      return failure("shop does not match") if expected && expected != shop_domain

      Result.new(success: true, shop_domain: shop_domain, error: nil)
    end

    def self.normalize_shop(value)
      text = value.to_s.strip.downcase
      return if text.blank?

      text = text.delete_prefix("https://").delete_prefix("http://")
      text.split("/", 2).first.presence
    end

    def self.shop_from_claim_hash(hash)
      dest_shop = shop_from_dest(hash["dest"])
      iss_shop = shop_from_iss(hash["iss"])
      return failure("shop claim missing") if dest_shop.blank? && iss_shop.blank?
      return failure("shop claims do not match") if dest_shop && iss_shop && dest_shop != iss_shop

      dest_shop || iss_shop
    end
    private_class_method :shop_from_claim_hash

    def self.shop_from_dest(dest)
      normalize_shop(dest)
    end

    def self.shop_from_iss(iss)
      normalize_shop(iss)
    end

    def self.stringify_keys(claims)
      return {} unless claims.respond_to?(:each_pair)

      claims.each_pair.with_object({}) { |(key, value), hash| hash[key.to_s] = value }
    end
    private_class_method :stringify_keys

    def self.failure(message)
      Result.new(success: false, shop_domain: nil, error: message)
    end
    private_class_method :failure
  end
end
