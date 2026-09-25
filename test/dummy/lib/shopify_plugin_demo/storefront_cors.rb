# frozen_string_literal: true

module ShopifyPluginDemo
  class StorefrontCors
    PATH_PREFIXES = ["/assets", "/shopify_plugin_demo/storefront"].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      if PATH_PREFIXES.any? { |prefix| env["PATH_INFO"].to_s.start_with?(prefix) }
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Cross-Origin-Resource-Policy"] = "cross-origin"
      end
      [status, headers, body]
    end
  end
end
