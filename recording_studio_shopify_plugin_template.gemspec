# frozen_string_literal: true

require_relative "lib/recording_studio_shopify_plugin_template/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_shopify_plugin_template"
  spec.version     = RecordingStudioShopifyPluginTemplate::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_shopify_plugin_template"
  spec.summary     = "Recording Studio Shopify plugin channel (Rails dummy host + Shopify CLI shell)"
  spec.description = "Dummy host and Shopify CLI shell for the Recording Studio Shopify plugin. " \
                     "Merchants Install in Shopify Admin, then Connect on the host."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
end
