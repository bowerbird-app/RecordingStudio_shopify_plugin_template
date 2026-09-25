# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class AdminJavascriptWiringTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "signed-in host layout importmap pins turbo and recording studio admin controllers" do
    user = User.find_or_create_by!(email: "admin-js-wiring@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    get root_path

    assert_response :success
    assert_includes response.body, "@hotwired/turbo-rails"
    assert_includes response.body, "recording_studio_admin/controllers"
  end
end
