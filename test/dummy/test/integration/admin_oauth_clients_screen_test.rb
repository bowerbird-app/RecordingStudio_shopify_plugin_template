# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class AdminOauthClientsScreenTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "oauth clients show page exposes lazy-loaded screen-table turbo frame" do
    user = User.find_or_create_by!(email: "admin-oauth-clients-screen@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    admin_root_recording = RecordingStudio.root_recording_for(admin_root)
    ShopifyPluginDemo::Tree.grant_admin!(root_recording: admin_root_recording, actor: user)

    get "/admin/screens/oauth_clients"

    assert_response :success
    assert_select "turbo-frame#screen-table[src$='/admin/screens/oauth_clients/table']"
  end

  test "oauth clients table region renders without requiring turbo in the browser" do
    user = User.find_or_create_by!(email: "admin-oauth-clients-table@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    admin_root_recording = RecordingStudio.root_recording_for(admin_root)
    ShopifyPluginDemo::Tree.grant_admin!(root_recording: admin_root_recording, actor: user)

    get "/admin/screens/oauth_clients/table"

    assert_response :success
    assert_includes response.media_type, "text/html"
  end
end
