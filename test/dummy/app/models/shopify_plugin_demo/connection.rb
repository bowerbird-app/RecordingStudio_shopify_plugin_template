# frozen_string_literal: true

# TODO(Oauth): stub row until RecordingStudio Oauth owns generic installs and HS256 session-token verify.
module ShopifyPluginDemo
  class Connection < ApplicationRecord
    self.table_name = "shopify_plugin_demo_connections"

    STATUSES = %w[installed connected].freeze

    validates :shop_domain, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    def connected?
      status == "connected"
    end

    def self.normalize_shop_domain(value)
      value.to_s.strip.downcase.presence
    end

    def self.for_shop(shop_domain)
      domain = normalize_shop_domain(shop_domain)
      return if domain.blank?

      find_by(shop_domain: domain)
    end

    def self.connect!(shop_domain)
      domain = normalize_shop_domain(shop_domain)
      raise ArgumentError, "shop domain required" if domain.blank?

      record = find_or_initialize_by(shop_domain: domain)
      record.status = "connected"
      record.connected_at = Time.current
      record.save!
      record
    end

    def self.disconnect!(shop_domain)
      domain = normalize_shop_domain(shop_domain)
      return if domain.blank?

      where(shop_domain: domain).delete_all
    end
  end
end
