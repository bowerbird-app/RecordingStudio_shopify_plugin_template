# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  module ShopifyShopMetafieldDefinitions
    NAMESPACE = ShopifyShopMetafieldPayload::NAMESPACE
    VERIFY_QUERY = <<~GRAPHQL.freeze
      query VerifyRecordingStudioAppMetafields {
        currentAppInstallation {
          hostBaseUrl: metafield(namespace: "#{NAMESPACE}", key: "host_base_url") { value }
          storefrontToken: metafield(namespace: "#{NAMESPACE}", key: "storefront_token") { value }
        }
      }
    GRAPHQL

    module_function

    def verify_query
      { query: VERIFY_QUERY }
    end
  end
end
