# Dummy App

This Rails app is the Recording Studio host for the Shopify plugin demo.

Sign in at `/users/sign_in` with `admin@admin.com` / `Password`. App Home lands on `/plugin_settings`. If the shop is not Connected, that request starts Oauth Connect (pick a workspace, then allow access). After Oauth, `/plugin_settings` shows Disconnect. `/shopify_plugin_demo/connect` starts the same Oauth path when the shop is not Connected. Pages at `/pages` lists each page in a FlatPack table. Open a row to preview the storefront widget. After Oauth Connect, host URL and storefront token write to Shopify app metafields when the App Home session token is still in session. A missing token still binds the shop and shows an alert that metafields did not sync. The theme block only asks for a page title. Storefront mount at `/shopify_plugin_demo/storefront/embed.js`. Named API `shopify_plugin_demo`.

Point Shopify App Home at `https://<HOST>/plugin_settings` with `HOST_BASE_URL`. See the repository README and `shopify/README.md`.
