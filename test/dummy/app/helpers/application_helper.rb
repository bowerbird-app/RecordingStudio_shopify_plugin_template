module ApplicationHelper
  DummyHostNavItem = Data.define(:key, :text, :icon)

  DUMMY_HOST_NAV = [
    DummyHostNavItem.new(key: :home, text: "Home", icon: :home),
    DummyHostNavItem.new(key: :recordings_tree, text: "Recordings tree", icon: :folder),
    DummyHostNavItem.new(key: :install, text: "Install", icon: :wrench),
    DummyHostNavItem.new(key: :pages, text: "Pages", icon: :document_text),
    DummyHostNavItem.new(key: :connect, text: "Connect", icon: :link),
    DummyHostNavItem.new(key: :api_keys, text: "API Keys", icon: :lock),
    DummyHostNavItem.new(key: :registered_apps, text: "Registered Apps", icon: :squares_2x2)
  ].freeze

  def dummy_host_nav_items
    DUMMY_HOST_NAV.map do |item|
      href = dummy_host_nav_href(item.key)
      {
        key: item.key,
        text: item.text,
        icon: item.icon,
        href: href,
        active: dummy_host_nav_active?(item.key, href)
      }
    end
  end

  def dummy_page_nav(title:, back_url: nil, back_label: "Home")
    content_for :title, title
  end

  def shopify_embed_query
    ShopifyPluginDemo::EmbedQuery.from_params(params)
  end

  def shopify_session_token
    ShopifyPluginDemo::EmbedQuery.session_token(params)
  end

  def shopify_plugin_demo_connect_url
    main_app.shopify_plugin_demo_connect_path(shopify_embed_query)
  end

  private

  def dummy_host_nav_href(key)
    case key
    when :home
      main_app.root_path
    when :recordings_tree
      main_app.docs_recordings_tree_path
    when :install
      main_app.docs_install_path
    when :pages
      main_app.pages_path
    when :connect
      main_app.shopify_plugin_demo_connect_path(shopify_embed_query)
    when :api_keys
      recording_studio_api.api_clients_path
    when :registered_apps
      recording_studio_admin_admin.screen_path("oauth_clients")
    else
      raise ArgumentError, "unknown nav key: #{key}"
    end
  end

  def dummy_host_nav_active?(key, href)
    case key
    when :home
      current_page?(main_app.root_path)
    when :recordings_tree
      current_page?(main_app.docs_recordings_tree_path)
    when :install
      current_page?(main_app.docs_install_path)
    when :pages
      request.path.start_with?("/pages")
    when :connect
      request.path.start_with?(main_app.shopify_plugin_demo_connect_path)
    when :api_keys
      request.path.start_with?(recording_studio_api.api_clients_path)
    when :registered_apps
      request.path.start_with?(recording_studio_admin_admin.screen_path("oauth_clients"))
    else
      current_page?(href)
    end
  end
end
