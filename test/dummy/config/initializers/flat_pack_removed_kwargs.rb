# frozen_string_literal: true

# FlatPack v0.1.311 dropped Card `style:` and PageNav `anchor_label` / `anchor_url`.
# Recording Studio 4.7 addons still pass those kwargs. Remap them so Bundler Audit
# can take view_component >= 4.14 without a full addon bump.

module ShopifyPluginDemo
  module FlatPackCardLegacyStyle
    CARD_STYLES = {
      default: {},
      outlined: {border: :default},
      interactive: {hover: :subtle}
    }.freeze

    def initialize(style: nil, **kwargs)
      kwargs = CARD_STYLES.fetch(style.to_sym, {}).merge(kwargs) unless style.nil?
      super(**kwargs)
    end
  end

  module FlatPackPageNavLegacyAnchors
    def initialize(**kwargs)
      href = kwargs.delete(:anchor_href).presence || kwargs.delete(:anchor_url).presence
      tooltip = kwargs.delete(:anchor_tooltip).presence || kwargs.delete(:anchor_label).presence
      icon = kwargs.delete(:anchor_icon)
      kwargs.delete(:show_back)
      kwargs.delete(:right_slot)
      kwargs.delete(:back_href)
      kwargs.delete(:back_icon)
      kwargs.delete(:back_tooltip)
      kwargs.delete(:back_label)
      kwargs.delete(:back_style)
      kwargs.delete(:back_size)
      kwargs.delete(:anchor_style)
      kwargs.delete(:anchor_size)
      super(**kwargs)
      return if href.blank?

      with_close(href: href, tooltip: tooltip, icon: icon)
    end
  end
end

Rails.application.config.to_prepare do
  unless FlatPack::Card::Component < ShopifyPluginDemo::FlatPackCardLegacyStyle
    FlatPack::Card::Component.prepend ShopifyPluginDemo::FlatPackCardLegacyStyle
  end

  unless FlatPack::PageNav::Component < ShopifyPluginDemo::FlatPackPageNavLegacyAnchors
    FlatPack::PageNav::Component.prepend ShopifyPluginDemo::FlatPackPageNavLegacyAnchors
  end
end
