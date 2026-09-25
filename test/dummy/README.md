# Dummy App

This Rails app is the Recording Studio host for the Shopify plugin demo.

Sign in at `/users/sign_in` with `admin@admin.com` / `Password`. App Home lands on `/plugin_settings`. Connect at `/shopify_plugin_demo/connect`. Pages at `/pages` lists each page in a FlatPack table; open a row to preview the storefront payload and copy its page id into the Shopify theme extension. Storefront mount at `/shopify_plugin_demo/storefront/embed.js`. Named API `shopify_plugin_demo`.

Point Shopify App Home at `https://<HOST>/plugin_settings` with `HOST_BASE_URL`. See the repository README and `shopify/README.md`.
