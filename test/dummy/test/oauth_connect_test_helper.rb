# frozen_string_literal: true

module OauthConnectTestHelper
  def complete_oauth_connect!(shop, token: nil)
    token ||= session_token_for(shop: shop)
    access = workspace_access_recording!

    get plugin_settings_path, params: { shop: shop, shopify_session_token: token }
    assert_response :redirect
    assert_includes response.redirect_url, "/recording_studio_oauth/oauth/authorize"
    query = oauth_query_from(response.redirect_url)

    get recording_studio_oauth.oauth_authorize_path(query.merge(access_recording_id: access.id))
    assert_response :success

    post recording_studio_oauth.oauth_authorize_path, params: query.merge(
      access_recording_id: access.id,
      role: "admin",
      decision: "connect"
    )
    assert_response :redirect
    follow_redirect!
    follow_redirect! if response.redirect?
  end

  def workspace_access_recording!
    workspace = Workspace.find_by!(name: "Studio Workspace")
    root = RecordingStudio.root_recording_for(workspace)
    ShopifyPluginDemo::Tree.grant_admin!(root_recording: root, actor: @user)
  end

  def oauth_query_from(url)
    uri = URI.parse(url)
    URI.decode_www_form(uri.query.to_s).to_h
  end
end
