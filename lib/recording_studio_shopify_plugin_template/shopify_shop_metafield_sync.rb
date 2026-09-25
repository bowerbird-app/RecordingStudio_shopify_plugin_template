# frozen_string_literal: true

require "json"

module RecordingStudioShopifyPluginTemplate
  module ShopifyShopMetafieldSync
    API_VERSION = "2025-01"

    private

    def ensure_definitions(access_token)
      message = ShopifyShopMetafieldDefinitions.ensure!(
        graphql_call: ->(body) { graphql(access_token, body) }
      )
      return message if message.is_a?(ShopifyShopMetafieldResult)
      return fail_with(message) if message.present?

      nil
    end

    def write_metafields(access_token, owner_id)
      payload = graphql(access_token, metafield_payload(owner_id))
      return payload if payload.is_a?(ShopifyShopMetafieldResult)

      set_error = metafields_set_error(payload)
      return set_error if set_error

      verify_written_metafields(access_token)
    rescue StandardError => e
      fail_with(e.message)
    end

    def metafields_set_error(payload)
      set_result = payload.dig("data", "metafieldsSet")
      return fail_with("metafieldsSet missing") if set_result.blank?

      user_errors = Array(set_result["userErrors"])
      return fail_with(user_errors.map { |row| row["message"] }.join(", ")) if user_errors.any?

      nil
    end

    def verify_written_metafields(access_token)
      payload = graphql(access_token, ShopifyShopMetafieldDefinitions.verify_query)
      return payload if payload.is_a?(ShopifyShopMetafieldResult)

      installation = payload.dig("data", "currentAppInstallation")
      return fail_with("app installation metafields missing") if installation.blank?

      host = installation.dig("hostBaseUrl", "value").to_s
      token = installation.dig("storefrontToken", "value").to_s
      return fail_with("host_base_url metafield blank after write") if host.blank?
      return fail_with("storefront_token metafield blank after write") if token.blank?

      ShopifyShopMetafieldResult.new(success: true, error: nil)
    end

    def metafield_payload(owner_id)
      ShopifyShopMetafieldPayload.set_payload(
        owner_id,
        host_base_url: @host_base_url,
        storefront_token: @request.storefront_token.to_s,
        pages: @request.pages
      )
    end

    def graphql(access_token, body)
      payload = @http.post(
        "https://#{@shop_domain}/admin/api/#{API_VERSION}/graphql.json",
        body: JSON.generate(body),
        headers: { "Content-Type" => "application/json", "X-Shopify-Access-Token" => access_token }
      )
      graphql_payload(payload)
    rescue StandardError => e
      fail_with(e.message)
    end

    def graphql_payload(payload)
      top_errors = Array(payload["errors"])
      return fail_with(graphql_errors_message(top_errors)) if top_errors.any?
      return fail_with("graphql data missing") if payload["data"].nil?

      payload
    end

    def graphql_errors_message(errors)
      errors.map { |row| row["message"].to_s.presence || row.to_s }.join(", ")
    end

    def fail_with(message)
      ShopifyShopMetafieldResult.new(success: false, error: message)
    end
  end
end
