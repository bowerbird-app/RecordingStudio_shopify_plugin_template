# frozen_string_literal: true

require "test_helper"

class ShopifyOauthConnectTest < ActiveSupport::TestCase
  test "finish fails without a code" do
    result = RecordingStudioShopifyPluginTemplate::ShopifyOauthConnect.finish(
      code: nil,
      client: RecordingStudioOauth::OauthClient.new,
      shop_domain: "demo.myshopify.com",
      connected_by: User.new
    )

    refute result.ok?
    assert_equal "Connect did not finish.", result.error
  end

  test "workspace root uses the parent root of the granted access" do
    workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    root = RecordingStudio.root_recording_for(workspace)
    access = Struct.new(:parent_recording).new(root)
    authorization = Struct.new(:manager_access_recording).new(access)

    assert_equal root, RecordingStudioShopifyPluginTemplate::ShopifyOauthConnect.workspace_root_for(authorization)
  end
end
