# Shopify CLI shell

BowerBird uses Shopify CLI for this channel. This folder is the thin app: TOML, App Home iframe, uninstall webhook, and a theme extension mount. It is not a React Admin rebuild.

## Point App Home at the dummy host

1. Boot the dummy host (`cd test/dummy && bin/dev`).
2. Set `HOST_BASE_URL` to that origin (for example `http://localhost:3000`).
3. Put the same origin in `shopify.app.toml` `application_url` when you run `shopify app dev`.
4. App Home (`app-home/index.html`) iframes `{HOST_BASE_URL}/shopify_plugin_demo/connect?shop=...`.
5. App Bridge `idToken()` appends `shopify_session_token`. The dummy host verifies HS256 through Oauth, then the Shopify plugin parses `dest` / `iss` and records the install.

Serve `app-home/` as the embedded application URL, or copy those two files behind the CLI web target you already use.

## Merchant path

1. Install the Shopify plugin from Partner Dashboard or `shopify app dev`.
2. Open App Home. That is Installed, not Connected.
3. Sign in on the dummy host if asked (`admin@admin.com` / `Password`).
4. Click Connect.

`app/uninstalled` posts to `{HOST_BASE_URL}/shopify_plugin_demo/uninstall` and deletes the Oauth external install row.

## Theme extension

`extensions/recording-studio-theme` is a Liquid block. Set Host URL, Page id, and Storefront token. Shop comes from `shop.permanent_domain`. The block loads `{host}/shopify_plugin_demo/storefront/embed.js` and mounts Embeddable HTML in the page. Do not iframe the host there.

Mint a token on the dummy host after Connect:

```ruby
client = RecordingStudioOauth::OauthClient.find_by!(
  client_id: ENV.fetch("SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID")
)
secret = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.secret_for(client)
token = RecordingStudioShopifyPluginTemplate::ShopifyStorefrontEmbed.mint(
  shop_domain: "demo.myshopify.com",
  page_recording_id: "PAGE_ID",
  secret: secret
)
```

Paste `token` into the theme editor. A shop that is only Installed, or a token for another shop, returns 404.
