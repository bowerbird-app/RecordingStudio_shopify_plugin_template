# frozen_string_literal: true

require "test_helper"

class FlatPackRemovedKwargsTest < ActiveSupport::TestCase
  test "card still accepts style from Recording Studio 4.7 addons" do
    html = ApplicationController.render(
      inline: "<%= render FlatPack::Card::Component.new(style: :outlined) { \"body\" } %>",
      layout: false
    )

    assert_includes html, "fp-card"
  end

  test "page nav still accepts anchor_url and anchor_label" do
    html = ApplicationController.render(
      inline: "<%= render FlatPack::PageNav::Component.new(anchor_url: \"/plugin_settings\", anchor_label: \"Close\") %>",
      layout: false
    )

    assert_includes html, "flat-pack-page-nav"
    assert_includes html, "/plugin_settings"
  end
end
