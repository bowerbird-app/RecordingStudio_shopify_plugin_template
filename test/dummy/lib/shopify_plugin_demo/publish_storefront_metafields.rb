# frozen_string_literal: true

module ShopifyPluginDemo
  module PublishStorefrontMetafields
    Result = RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldResult

    module_function

    def call(shop_domain:, client:, root_recording:, session_token:, host_base_url:, http: nil)
      return fail_with("session token required") if session_token.to_s.blank?

      secret = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(client)
      token = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
        shop_domain: shop_domain,
        secret: secret
      )
      return fail_with("storefront token missing") if token.blank?

      RecordingStudioShopifyPluginTemplate::ShopifyShopMetafields.sync!(
        request: RecordingStudioShopifyPluginTemplate::ShopifyShopMetafieldRequest.new(
          shop_domain: shop_domain,
          client: client,
          session_token: session_token,
          host_base_url: host_base_url,
          storefront_token: token,
          pages: pages_for(root_recording)
        ),
        http: http
      )
    end

    def pages_for(root_recording)
      RecordingStudio::Recording
        .includes(:recordable)
        .where(recordable_type: "Page", trashed_at: nil, root_recording_id: root_recording.id)
        .order(:created_at, :id)
        .map { |recording| { "id" => recording.id, "title" => recording.recordable.title } }
    end

    def fail_with(message)
      Result.new(success: false, error: message)
    end
    private_class_method :fail_with
  end
end
