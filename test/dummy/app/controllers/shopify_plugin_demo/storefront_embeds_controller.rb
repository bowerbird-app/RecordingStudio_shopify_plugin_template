# frozen_string_literal: true

class ShopifyPluginDemo::StorefrontEmbedsController < ActionController::Base
  skip_forgery_protection

  CACHE_SECONDS = 60

  def show
    page_recording = find_page_recording(params[:page_id])
    grant = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.authorize(
      token: params[:token],
      shop_domain: params[:shop],
      client: registered_app,
      page_recording: page_recording
    )
    unless grant.ok? && page_recording&.embed_enabled?
      deny_embed
      return
    end

    render_result = RecordingStudioEmbeddable::RenderPayload.call(
      recording: page_recording,
      embed: page_recording.embed
    )
    unless render_result.success?
      deny_embed
      return
    end

    payload = render_result.value
    cache_payload_headers(payload)
    respond_to do |format|
      format.json { render json: payload.to_h }
      format.js { render js: mount_javascript(payload) }
    end
  end

  private

  def find_page_recording(page_id)
    return if page_id.blank?

    RecordingStudio::Recording.find_by(id: page_id, recordable_type: "Page", trashed_at: nil)
  end

  def registered_app
    client_id = RecordingStudioShopifyPluginTemplate.configuration.registered_app_client_id
    return if client_id.blank?

    RecordingStudioOauth::OauthClient.find_by(client_id: client_id)
  end

  def deny_embed
    response.set_header("Cache-Control", "private, no-store")
    respond_to do |format|
      format.json { head :not_found }
      format.js { head :not_found }
    end
  end

  def cache_payload_headers(payload)
    response.set_header("Cache-Control", "public, max-age=#{CACHE_SECONDS}")
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Cross-Origin-Resource-Policy", "cross-origin")
    last_modified = payload.metadata&.last_modified_at
    response.set_header("Last-Modified", last_modified.httpdate) if last_modified
  end

  def mount_javascript(payload)
    mount_id = params[:mount].to_s
    <<~JS
      (function () {
        var root = document.getElementById(#{mount_id.to_json});
        if (!root) return;
        root.innerHTML = #{payload.html.to_json};
      })();
    JS
  end
end
