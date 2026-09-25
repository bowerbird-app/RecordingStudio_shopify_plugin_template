# Shopify CLI shell

BowerBird uses Shopify CLI for this channel. This folder is the thin app: TOML, App Home iframe, uninstall webhook, and a theme extension mount. It is not a React Admin rebuild.

## Point App Home at the dummy host

1. Boot the dummy host (`cd test/dummy && bin/dev`).
2. Set `HOST_BASE_URL` to that origin (for example `http://localhost:3000`).
3. Put `https://<HOST>/plugin_settings` in Partner Dev Dashboard App URL and in `shopify.app.toml` `application_url` when you run `shopify app dev`. The TOML in this repo uses the placeholder `https://example.com/plugin_settings`. Do not commit a live ngrok hostname. The Partner **active version** App URL must include `/plugin_settings`. Configuration alone is not enough if the active version still points at `/`.
4. App Home (`app-home/index.html`) iframes `{HOST_BASE_URL}/plugin_settings?shop=...`. If the shop is not Connected, the dummy redirects to Connect. If it is Connected, App Home shows Shopify plugin settings with Disconnect only.
5. App Bridge `idToken()` appends `shopify_session_token`. The dummy host verifies HS256 through Oauth, then the Shopify plugin parses `dest` / `iss` and records the install.

Serve `app-home/` as the embedded application URL, or copy those two files behind the CLI web target you already use.

### Session cookies in the App Home iframe

App Home loads the dummy host in a cross-site iframe (`admin.shopify.com` → your tunnel or production origin). The dummy sets the Rails session cookie to `SameSite=None` with `Secure` on HTTPS (or when `config.force_ssl` is on). Plain `http://localhost` keeps `SameSite=Lax` without `Secure` for top-level dev. Top-level login in the browser was only a workaround when the session stayed `Lax` and would not stick inside the iframe.

## Merchant path

1. Install the Shopify plugin from Partner Dashboard or `shopify app dev`.
2. Open App Home. That is Installed, not Connected. The iframe lands on `/plugin_settings` and redirects to Connect until you Connect.
3. Sign in on the dummy host if asked (`admin@admin.com` / `Password`).
4. Click Connect. App Home then shows Shopify plugin settings with Disconnect. Disconnect is a host soft disconnect. It does not uninstall the Shopify plugin.

`app/uninstalled` posts to `{HOST_BASE_URL}/shopify_plugin_demo/uninstall`. The dummy checks `X-Shopify-Hmac-Sha256` against the raw body with the Registered App session token secret (the Partner API secret). A valid stamp then calls `ShopifyInstall.remove`. A missing or forged stamp returns 401 and leaves the install row.

## Theme extension

`extensions/recording-studio-theme` is a Liquid block. Pick a page by title. Host URL and storefront token come from app metafields written on Connect. Shop comes from `shop.permanent_domain`. The block loads `{host}/shopify_plugin_demo/storefront/embed.js` and mounts Embeddable HTML plus FlatPack CSS and Stimulus. Do not iframe the host there.

Connect writes those metafields when the App Home session token is present on the Connect POST. Click Connect, not only Use this shop. If the POST has no session token, the shop can still bind. The host then stays on Connect with an alert that metafields did not sync. Open Connect from App Home so `id_token` is present, then Connect again. A shop that is only Installed, or a token for another shop, returns 404.

## Partner smoke on development-store-kwcwfmcz

Marikit runs this on the Partner store tomorrow. Do not run `shopify app deploy` from a Cloud Agent.

Set these on the dummy host before you start.

- `HOST_BASE_URL` is the public dummy origin the CLI tunnel will call.
- `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID` is the Oauth Registered App id (`rsoauth_oc_…`).
- That Registered App session token secret is the Partner app API secret. HMAC and session tokens share it.

### Install and Connect

1. Boot the dummy (`cd test/dummy && bin/dev`).
2. From `shopify/`, run `shopify app dev` and install on `development-store-kwcwfmcz`.
3. Open App Home. You should see Connect after the `/plugin_settings` redirect. Installed is not Connected.
4. Sign in if asked (`admin@admin.com` / `Password`). Click Connect. After Connect, the dummy returns to `/plugin_settings` for that shop. You should see Shopify plugin settings and Disconnect.

Pass. The Oauth external install row exists for that shop and Registered App, and Connect shows Connected.

### Uninstall HMAC

1. In Shopify Admin, uninstall the app from `development-store-kwcwfmcz`.
2. Confirm the Oauth install row is gone for that shop and `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID`.

Pass. The row is gone after Shopify posts `app/uninstalled`.

3. Reinstall and Connect again so a row exists.
4. POST a forged body to `{HOST_BASE_URL}/shopify_plugin_demo/uninstall` with a junk `X-Shopify-Hmac-Sha256` header.

```bash
curl -i -X POST "$HOST_BASE_URL/shopify_plugin_demo/uninstall" \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: forged" \
  -d '{"shop":"development-store-kwcwfmcz.myshopify.com"}'
```

Pass. HTTP 401. The install row is still there.

Theme block is optional for this smoke. Skip it unless you are also checking storefront embed.
