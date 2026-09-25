# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  module ShopifyShopMetafieldDefinitions
    NAMESPACE = ShopifyShopMetafieldPayload::NAMESPACE
    KEYS = [
      { key: "host_base_url", type: "single_line_text_field", name: "Recording Studio host URL" },
      { key: "storefront_token", type: "single_line_text_field", name: "Recording Studio storefront token" },
      { key: "pages", type: "json", name: "Recording Studio pages" }
    ].freeze
    CREATE_DEFINITION = <<~GRAPHQL
      mutation MetafieldDefinitionCreate($definition: MetafieldDefinitionInput!) {
        metafieldDefinitionCreate(definition: $definition) {
          createdDefinition { id }
          userErrors { field message code }
        }
      }
    GRAPHQL
    VERIFY_QUERY = <<~GRAPHQL.freeze
      query VerifyRecordingStudioAppMetafields {
        currentAppInstallation {
          hostBaseUrl: metafield(namespace: "#{NAMESPACE}", key: "host_base_url") { value }
          storefrontToken: metafield(namespace: "#{NAMESPACE}", key: "storefront_token") { value }
        }
      }
    GRAPHQL

    module_function

    def ensure!(graphql_call:)
      KEYS.each do |spec|
        error = ensure_definition(graphql_call, spec)
        return error if error
      end
      nil
    end

    def ensure_definition(graphql_call, spec)
      payload = graphql_call.call(
        query: CREATE_DEFINITION,
        variables: { definition: definition_input(spec) }
      )
      return payload if payload.is_a?(ShopifyShopMetafieldResult)

      definition_result = payload.dig("data", "metafieldDefinitionCreate")
      return "metafieldDefinitionCreate missing" if definition_result.blank?

      blocking = Array(definition_result["userErrors"]).reject { |row| definition_exists?(row) }
      blocking.map { |row| row["message"] }.join(", ") if blocking.any?
    end
    private_class_method :ensure_definition

    def verify_query
      { query: VERIFY_QUERY }
    end

    def definition_input(spec)
      {
        namespace: NAMESPACE,
        key: spec.fetch(:key),
        name: spec.fetch(:name),
        type: spec.fetch(:type),
        ownerType: "APP_INSTALLATION",
        access: { admin: "MERCHANT_READ_WRITE", storefront: "PUBLIC_READ" }
      }
    end
    private_class_method :definition_input

    def definition_exists?(row)
      message = row["message"].to_s.downcase
      code = row["code"].to_s
      code == "TAKEN" || message.include?("already") || message.include?("taken")
    end
    private_class_method :definition_exists?
  end
end
