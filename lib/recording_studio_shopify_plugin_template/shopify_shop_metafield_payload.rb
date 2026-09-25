# frozen_string_literal: true

require "json"

module RecordingStudioShopifyPluginTemplate
  module ShopifyShopMetafieldPayload
    NAMESPACE = "$app:recording_studio"
    SET_METAFIELDS = <<~GRAPHQL
      mutation MetafieldsSet($metafields: [MetafieldsSetInput!]!) {
        metafieldsSet(metafields: $metafields) { userErrors { field message } }
      }
    GRAPHQL

    module_function

    def set_payload(shop_gid, host_base_url:, storefront_token:, pages:)
      {
        query: SET_METAFIELDS,
        variables: {
          metafields: [
            field(shop_gid, "host_base_url", "single_line_text_field", host_base_url),
            field(shop_gid, "storefront_token", "single_line_text_field", storefront_token),
            field(shop_gid, "pages", "json", JSON.generate(Array(pages)))
          ]
        }
      }
    end

    def field(owner_id, key, type, value)
      { ownerId: owner_id, namespace: NAMESPACE, key: key, type: type, value: value }
    end
  end
end
