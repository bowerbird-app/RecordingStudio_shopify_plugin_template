# frozen_string_literal: true

RecordingStudioOauth.configure do |config|
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
  config.admin_root_recordable_type_names = ["AdminRoot"]
  config.api_mount_path = "/recording_studio_api"
  config.engine_mount_path = "/recording_studio_oauth"
  config.mcp_mount_path = "/recording_studio_mcp"
  config.register_origin_as_protected_resource = false
  config.extra_protected_resource_paths = []
end

RecordingStudioShopifyPluginTemplate.configure do |config|
  config.registered_app_client_id = ENV["SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID"]
end
