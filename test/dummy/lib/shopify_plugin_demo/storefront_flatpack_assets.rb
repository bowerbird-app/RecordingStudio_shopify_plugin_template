# frozen_string_literal: true

require "json"

module ShopifyPluginDemo
  module StorefrontFlatpackAssets
    STYLESHEETS = [
      "application",
      "flat_pack/variables",
      "flat_pack/application",
      "flat_pack/rich_text",
      "tailwind"
    ].freeze

    module_function

    def stylesheet_urls(resolver:, base_url:)
      STYLESHEETS.filter_map do |name|
        absolute_url(base_url, resolver.stylesheet_path(name))
      rescue StandardError
        nil
      end
    end

    def importmap_json(resolver:, base_url:)
      parsed = JSON.parse(Rails.application.importmap.to_json(resolver: resolver))
      parsed.fetch("imports").transform_values! { |path| absolute_url(base_url, path) }
      parsed.to_json
    end

    def absolute_url(base_url, path)
      return path if path.to_s.start_with?("http://", "https://")

      "#{base_url}#{path}"
    end
  end
end
