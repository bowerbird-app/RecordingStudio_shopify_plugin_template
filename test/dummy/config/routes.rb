Rails.application.routes.draw do
  devise_for :users,
             skip: %i[sessions registrations passwords],
             controllers: {
               confirmations: "recording_studio_user/auth/confirmations",
               omniauth_callbacks: "recording_studio_user/omniauth_callbacks"
             }

  recording_studio_user_auth_for :users

  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
  mount RecordingStudioAccessible::Engine, at: "/admin/access", as: :recording_studio_admin_access
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioApi::Engine, at: "/recording_studio_api"
  mount RecordingStudioEmbeddable::Engine, at: "/recording_studio_embeddable"
  mount RecordingStudioOauth::Engine, at: "/recording_studio_oauth"
  mount RecordingStudioAttachable::Engine, at: "/recording_studio_attachable"
  mount RecordingStudioSiteSettings::Engine, at: "/recording_studio_site_settings"

  get "/.well-known/oauth-authorization-server",
      to: "recording_studio_oauth/oauth_discoveries#authorization_server",
      defaults: { api_key: "public" }
  RecordingStudioOauth::ProtectedResourceRegistry.draw_origin_well_known(self)

  recording_studio_admin_for :admin, at: "/admin", root_section: :root

  get "up" => "rails/health#show", as: :rails_health_check

  get "docs/install", to: "docs#install", as: :docs_install
  get "docs/config", to: "docs#configuration", as: :docs_config
  get "docs/recordable_types", to: "docs#recordable_types", as: :docs_recordable_types
  get "docs/recordings_tree", to: "docs#recordings_tree", as: :docs_recordings_tree
  get "docs/gem_views", to: "docs#gem_views", as: :docs_gem_views
  get "docs/methods", to: "docs#methods", as: :docs_methods

  resources :pages, only: %i[index show] do
    member do
      get :embed_preview
    end
  end

  get "plugin_settings", to: "plugin_settings#show", as: :plugin_settings
  get "shopify_plugin_demo/connect", to: "shopify_plugin_demo/connections#show", as: :shopify_plugin_demo_connect
  post "shopify_plugin_demo/connect", to: "shopify_plugin_demo/connections#create"
  delete "shopify_plugin_demo/connect", to: "shopify_plugin_demo/connections#destroy", as: :shopify_plugin_demo_disconnect
  post "shopify_plugin_demo/uninstall", to: "shopify_plugin_demo/uninstalls#create"
  get "shopify_plugin_demo/storefront/embed.css",
      to: "shopify_plugin_demo/storefront_embeds#stylesheet",
      format: false
  get "shopify_plugin_demo/storefront/embed_boot.js", to: "shopify_plugin_demo/storefront_embeds#boot"
  get "shopify_plugin_demo/storefront/embed",
      to: "shopify_plugin_demo/storefront_embeds#show",
      constraints: { format: /js|json/ }

  root "home#index"

  mount RecordingStudioUser::Engine => RecordingStudioUser.config.mount_path, as: :recording_studio_users
end
