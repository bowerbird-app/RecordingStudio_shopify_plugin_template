# frozen_string_literal: true

require "test_helper"

class RecordingStudioShopifyPluginTemplateTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.3.2", ::RecordingStudioShopifyPluginTemplate::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioShopifyPluginTemplate::Engine
  end

  def test_gemspec_pins_recording_studio_and_oauth
    gemspec = File.read(File.expand_path("../recording_studio_shopify_plugin_template.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_oauth", "~> 0.5.3"'
  end

  def test_gemspec_excludes_cursor_config
    spec = Gem::Specification.load(File.expand_path("../recording_studio_shopify_plugin_template.gemspec", __dir__))
    cursor_files = spec.files.select { |path| path == ".cursor" || path.split("/").include?(".cursor") }

    assert_empty cursor_files, "gemspec must not package .cursor/ (got #{cursor_files.inspect})"
  end

  def test_cursor_environment_is_repo_managed_without_snapshot
    path = File.expand_path("../.cursor/environment.json", __dir__)
    json = JSON.parse(File.read(path))

    assert_equal "recording-studio-shopify-plugin-demo", json["name"]
    assert_equal ".cursor/install.sh", json["install"]
    assert_equal ".cursor/start.sh", json["start"]
    refute json.key?("snapshot"), "snapshot pins a Personal build and skips install"
    refute json.key?("agentCanUpdateSnapshot")
  end

  def test_cursor_install_still_fetches_skills
    install_script = File.read(File.expand_path("../.cursor/install.sh", __dir__))

    assert_includes install_script, "fetch-skills.sh"
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.9.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.190"'
    refute_includes gemfile, "recording_studio/v3.0.0"
    refute_includes gemfile, 'tag: "v0.1.133"'
    refute_includes gemfile, 'tag: "v0.6.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_Oauth", tag: "v0.5.3"'
  end

  def test_dummy_schema_includes_accessible_depends_on_recording_id
    schema = File.read(File.expand_path("dummy/db/schema.rb", __dir__))
    migration = File.read(
      File.expand_path(
        "dummy/db/migrate/20260911024811_add_depends_on_recording_id_to_recording_studio_accesses.rb",
        __dir__
      )
    )

    assert_includes schema, 't.uuid "depends_on_recording_id"'
    assert_includes schema, "index_recording_studio_accesses_on_depends_on_recording_id"
    assert_includes migration, "add_column :recording_studio_accesses, :depends_on_recording_id, :uuid"
  end

  def test_template_does_not_ship_copied_core_hooks_or_base_service
    refute File.exist?(File.expand_path("../lib/recording_studio_shopify_plugin_template/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_shopify_plugin_template/services/base_service.rb",
                                        __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_shopify_plugin_template/services/example_service.rb",
                                        __dir__))
  end

  def test_example_capability_wraps_include_for_and_is_not_enabled_globally
    source = File.read(File.expand_path("../lib/recording_studio_shopify_plugin_template/capabilities/example.rb",
                                        __dir__))

    assert_includes source, "def self.to(**)"
    assert_includes source, "RecordingStudio::Capabilities.include_for(:example, **)"
    refute_includes source, "enable_capability"
    refute_includes source, "set_capability_options"
    refute RecordingStudio.capability_enabled?(:example, for: "Folder")
    refute RecordingStudio.capability_enabled?(:example, for: "Page")
    assert_empty RecordingStudio.configuration.enabled_recordable_types_for(:example)
  end

  def test_dummy_app_uses_host_sidebar_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)

    assert_includes controller_source, "include RecordingStudio::UsesDefaultLayout"
    assert_includes controller_source, "devise_controller? ? \"application\" : \"host\""
    refute_includes controller_source, '"recording_studio/default_layout"'
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/host.html.erb", __dir__))
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"

    auth_layout = File.read(File.expand_path("dummy/app/views/layouts/recording_studio_user/auth.html.erb", __dir__))
    assert_includes auth_layout, 'stylesheet_link_tag "flat_pack/application"'
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "../../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "flatpack-*/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "../../../vendor/bundle/**/recording_studio/app/views/**/*.erb"
    assert_includes tailwind_source, "recordingstudio-*/app/views/**/*.erb"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, "\"Workspace\""
    assert_includes initializer_source, "\"Folder\""
    assert_includes initializer_source, "\"Page\""
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "Shopify plugin demo"
    assert_includes readme_source, "/shopify_plugin_demo/connect"
    assert_includes readme_source, "shopify_plugin_demo"
    refute_includes readme_source, "flat_pack_sidebar"
  end

  def test_product_readme_is_the_template_guide
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "RecordingStudio"
    assert_includes readme, "v4.2.0"
    assert_includes readme, "v0.1.190"
    assert_includes readme, "v0.9.1"
    assert_includes readme, "v0.5.3"
    refute_includes readme, "v0.1.133"
    refute_includes readme, "v3 declarations"
    refute_includes readme, "RecordingStudio v3"
    refute_includes readme, "ExampleService"
    refute_includes readme, "recording_studio/v3.0.0"
  end

  def test_dummy_home_page_uses_demo_title_only
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "ShopifyPluginDemo::ProductConfig::CHANNEL_NAME"
    assert_includes view_source, "ShopifyPluginDemo::ProductConfig::NAME"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "dummy_page_nav"
    refute_includes view_source, 'title: "Demo"'
    refute_includes view_source, "FlatPack::Breadcrumb::Component"
  end

  def test_dummy_docs_pages_use_minimal_flatpack_documentation_components
    docs_view_paths = Dir[File.expand_path("dummy/app/views/docs/*.html.erb", __dir__)].reject do |view_path|
      File.basename(view_path).start_with?("_")
    end
    refute_empty docs_view_paths

    docs_view_paths.each do |view_path|
      view_source = File.read(view_path)

      assert_includes view_source, "dummy_page_nav"
      assert_includes view_source, "FlatPack::PageTitle::Component"
      refute_includes view_source, "FlatPack::Card::Component"
      refute_includes view_source, "FlatPack::Breadcrumb::Component"
    end

    methods_view = File.read(File.expand_path("dummy/app/views/docs/methods.html.erb", __dir__))
    assert_includes methods_view, "FlatPack::SectionTitle::Component"
    assert_includes methods_view, "FlatPack::CodeBlock::Component"

    gem_views_view = File.read(File.expand_path("dummy/app/views/docs/gem_views.html.erb", __dir__))
    assert_includes gem_views_view, "FlatPack::Table::Component"
    refute_includes gem_views_view, "FlatPack::List::Component"

    recordable_types_view = File.read(File.expand_path("dummy/app/views/docs/recordable_types.html.erb", __dir__))
    assert_includes recordable_types_view, "FlatPack::List::Component"
    refute_includes recordable_types_view, "v3 parent/root"

    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_dummy_recordings_tree_view_omits_structure_section_copy
    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))

    assert_includes recordings_tree_view, 'title: "Recordings tree"'
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    recording_tree_partial = File.read(File.expand_path("dummy/app/views/docs/_recording_tree_node.html.erb", __dir__))
    assert_includes recording_tree_partial, "parent_builder.node"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_shopify_plugin_template/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end

  def test_stub_connection_table_is_gone
    refute File.exist?(File.expand_path("dummy/app/models/shopify_plugin_demo/connection.rb", __dir__))
    schema = File.read(File.expand_path("dummy/db/schema.rb", __dir__))
    refute_includes schema, "shopify_plugin_demo_connections"
    assert_includes schema, "recording_studio_oauth_external_installs"
    migrate_path = File.expand_path(
      "dummy/db/migrate/20260924040000_add_oauth_session_token_verify_and_drop_stub_connections.rb",
      __dir__
    )
    assert_includes File.read(migrate_path), "shopify_plugin_demo_connections"
  end
end
