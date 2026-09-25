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

  def boot
    response.set_header("Cache-Control", "public, max-age=#{CACHE_SECONDS}")
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Cross-Origin-Resource-Policy", "cross-origin")
    render js: boot_javascript, content_type: "text/javascript"
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
    stylesheet_urls = ShopifyPluginDemo::StorefrontFlatpackAssets.stylesheet_urls(
      resolver: view_context,
      base_url: request.base_url
    )
    importmap = ShopifyPluginDemo::StorefrontFlatpackAssets.importmap_json(
      resolver: view_context,
      base_url: request.base_url
    )
    boot_src = "#{request.base_url}#{ShopifyPluginDemo::Contract.storefront_embed_boot_path}"
    <<~JS
      (function () {
        var mountId = #{mount_id.to_json};
        var html = #{payload.html.to_json};
        var styles = #{stylesheet_urls.to_json};
        var importmapText = #{importmap.to_json};
        var bootSrc = #{boot_src.to_json};

        function paint() {
          var root = document.getElementById(mountId);
          if (!root) return false;
          root.setAttribute("data-theme", "rounded");
          root.innerHTML = html;
          styles.forEach(function (href) {
            if (document.querySelector('link[href="' + href + '"]')) return;
            var link = document.createElement("link");
            link.rel = "stylesheet";
            link.href = href;
            document.head.appendChild(link);
          });
          if (!document.querySelector("script[data-shopify-plugin-demo-importmap]")) {
            var map = document.createElement("script");
            map.type = "importmap";
            map.setAttribute("data-shopify-plugin-demo-importmap", "true");
            map.textContent = importmapText;
            document.head.appendChild(map);
          }
          if (!document.querySelector("script[data-shopify-plugin-demo-boot]")) {
            var boot = document.createElement("script");
            boot.type = "module";
            boot.src = bootSrc;
            boot.setAttribute("data-shopify-plugin-demo-boot", "true");
            document.head.appendChild(boot);
          }
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

  def boot_javascript
    <<~JS
      import { Application } from "@hotwired/stimulus"
      import TooltipController from "controllers/flat_pack/tooltip_controller"
      import CarouselController from "controllers/flat_pack/carousel_controller"

      const started = window.ShopifyPluginDemoStimulus || Application.start()
      window.ShopifyPluginDemoStimulus = started
      started.register("flat-pack--tooltip", TooltipController)
      started.register("flat-pack--carousel", CarouselController)
    JS
  end
end
