# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
begin
  require "minitest/mock"
rescue LoadError
  require_relative "support/object_stub"
end
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_shopify_plugin_template"
