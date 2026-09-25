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

  def stylesheet
    cors_asset_headers
    send_data ShopifyPluginDemo::StorefrontFlatpackAssets.stylesheet_css,
              type: "text/css; charset=utf-8",
              disposition: "inline"
  end

  def boot
    cors_asset_headers
    render js: File.read(Rails.root.join("app/javascript/shopify_plugin_demo/storefront_classic_boot.js")),
           content_type: "text/javascript"
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
    cors_asset_headers
    last_modified = payload.metadata&.last_modified_at
    response.set_header("Last-Modified", last_modified.httpdate) if last_modified
  end

  def cors_asset_headers
    response.set_header("Cache-Control", "public, max-age=#{CACHE_SECONDS}")
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Cross-Origin-Resource-Policy", "cross-origin")
  end

  def mount_javascript(payload)
    mount_id = params[:mount].to_s
    <<~JS
      (function () {
        var mountId = #{mount_id.to_json};
        var html = #{payload.html.to_json};

        function paint() {
          var root = document.getElementById(mountId);
          if (!root) return false;
          root.setAttribute("data-theme", "rounded");
          root.innerHTML = html;
          return true;
        }

        function waitForMount() {
          if (paint()) return;
          var attempts = 0;
          var maxAttempts = 120;
          function tick() {
            if (paint()) return;
            attempts += 1;
            if (attempts >= maxAttempts) return;
            if (typeof requestAnimationFrame === "function") {
              requestAnimationFrame(tick);
            } else {
              setTimeout(tick, 16);
            }
          }
          if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", tick, { once: true });
          } else {
            tick();
          }
        }

        waitForMount();
      })();
    JS
  end
end
