# frozen_string_literal: true

require "test_helper"

class EmbedMemberActionTest < ActionDispatch::IntegrationTest
  setup do
    @client = ShopifyPluginDemo::Provision.isolated_client!
  end

  test "named actions embed returns schema v1" do
    get ShopifyPluginDemo::Contract.actions_embed_path(@client.page_recording_id),
        headers: @client.bearer_headers.merge("Accept" => "application/json")

    assert_response :ok
    payload = ShopifyPluginDemo::Contract.parse_browser_payload!(JSON.parse(response.body))
    assert_equal 1, payload.schema_version
  end

  test "named embed without bearer is unauthorized" do
    get ShopifyPluginDemo::Contract.actions_embed_path(@client.page_recording_id),
        headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "named token does not use public embed path" do
    get ShopifyPluginDemo::Contract.public_actions_embed_path(@client.page_recording_id),
        headers: @client.bearer_headers.merge("Accept" => "application/json")

    refute_equal 200, response.status
  end
end
