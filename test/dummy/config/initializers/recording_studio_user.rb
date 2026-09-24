# frozen_string_literal: true

RecordingStudioUser.configure do |config|
  config.user_class_name = "User"
  config.mount_path = "/recording_studio_users"
  config.profile_route_path = "profile"
  config.admin_route_path = "admin"
  config.layout = "application"
  config.additional_profile_attributes = []
  config.require_password_confirmation = false
  config.omniauth_providers = {}
  config.omniauth_create_account = true
  config.otp_enabled = false
end
