# frozen_string_literal: true

Rails.application.configure do
  config.action_dispatch.default_headers.delete("X-Frame-Options")

  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_ancestors :self, "https://admin.shopify.com", "https://*.myshopify.com"
  end
end
