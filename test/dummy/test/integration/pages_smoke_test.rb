# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PagesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    load Rails.root.join("db/seeds.rb").to_s unless Page.exists?(title: "Carousel")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: Page.find_by!(title: "Getting Started"))
    @carousel_recording = RecordingStudio::Recording.find_by!(recordable: Page.find_by!(title: "Carousel"))
    sign_in @user
  end

  test "index lists pages in a flatpack table with links and page ids" do
    get pages_path

    assert_response :success
    assert_select "table"
    assert_select "th", text: "Title"
    assert_select "th", text: "Page id"
    assert_select "a[href=?]", page_path(@page_recording), text: "Getting Started"
    assert_select "a[href=?]", page_path(@carousel_recording), text: "Carousel"
    assert_includes response.body, @page_recording.id
  end

  test "getting started show keeps host chrome and a storefront card" do
    get page_path(@page_recording)

    assert_response :success
    assert_includes response.body, "Page id #{@page_recording.id}"
    assert_includes response.body, "test widget"
    assert_includes response.body, "flat-pack--tooltip"
    refute_select 'article[data-shopify-plugin-demo-embed="page"] h1'
  end

  test "carousel show renders a flatpack carousel" do
    get page_path(@carousel_recording)

    assert_response :success
    assert_includes response.body, "flat-pack--carousel"
    assert_includes response.body, "Slide one"
  end

  test "embed preview still renders the shared payload partial" do
    get embed_preview_page_path(@page_recording)

    assert_response :success
    assert_select 'article[data-shopify-plugin-demo-embed="page"]'
    assert_includes response.body, "test widget"
    refute_includes response.body, @page_recording.id
  end
end
