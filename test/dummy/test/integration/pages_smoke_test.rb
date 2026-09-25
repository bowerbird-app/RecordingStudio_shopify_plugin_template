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
    load Rails.root.join("db/seeds.rb").to_s unless Page.exists?
    @page_recording = RecordingStudio::Recording.find_by!(recordable: Page.find_by!(title: "Getting Started"))
    sign_in @user
  end

  test "index lists pages in a flatpack table with links and page ids" do
    get pages_path

    assert_response :success
    assert_select "table"
    assert_select "th", text: "Title"
    assert_select "th", text: "Page id"
    assert_select "a[href=?]", page_path(@page_recording), text: @page_recording.recordable.title
    assert_includes response.body, @page_recording.id
  end

  test "show renders the storefront preview markup" do
    get page_path(@page_recording)

    assert_response :success
    assert_includes response.body, "Page id #{@page_recording.id}"
    assert_select 'article[data-shopify-plugin-demo-embed="page"] h1', text: @page_recording.recordable.title
  end

  test "embed preview still renders the shared payload partial" do
    get embed_preview_page_path(@page_recording)

    assert_response :success
    assert_select 'article[data-shopify-plugin-demo-embed="page"]'
  end
end
