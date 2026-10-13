# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_shopify_plugin_template.gemspec
gemspec

# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.213"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.5.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.15.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.2.0"
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v0.5.6"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.15.0"
# Attachable 0.14+ requires metrics ~> 0.2 (not on RubyGems); smallest tag v0.2.0
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.0"
gem "recording_studio_oauth", github: "bowerbird-app/RecordingStudio_Oauth", tag: "v0.9.0"
# Oauth 0.9+ / Users 0.21+ / Root Switchable 0.9+ require cache ~> 0.5 (not on RubyGems)
gem "recording_studio_cache", github: "bowerbird-app/RecordingStudio_cache", tag: "v0.5.0"
gem "recording_studio_site_settings", github: "bowerbird-app/RecordingStudio_site_settings", tag: "v0.1.2"

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
