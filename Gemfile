# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_shopify_plugin_template.gemspec
gemspec

# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.190"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.9.1"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.0.2"
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v0.5.6"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.5.1"
gem "recording_studio_oauth", github: "bowerbird-app/RecordingStudio_Oauth", tag: "v0.5.3"
gem "recording_studio_site_settings", github: "bowerbird-app/RecordingStudio_site_settings", tag: "v0.1.0"

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
