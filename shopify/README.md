# Shopify CLI shell

BowerBird uses Shopify CLI for this channel. This folder is the thin app: TOML, App Home iframe, uninstall webhook, and a theme extension mount. It is not a React Admin rebuild.

## Point App Home at the dummy host

1. Boot the dummy host (`cd test/dummy && bin/dev`).
2. Set `HOST_BASE_URL` to that origin (for example `http://localhost:3000`).
3. Put `https://<HOST>/plugin_settings` in Partner Dev Dashboard App URL and in `shopify.app.toml` `application_url` when you run `shopify app dev`. The TOML in this repo uses the placeholder `https://example.com/plugin_settings`. Do not commit a live ngrok hostname. The Partner **active version** App URL must include `/plugin_settings`. Configuration alone is not enough if the active version still points at `/`.

**`automatically_update_urls_on_dev` must stay `false`.** The Shopify CLI strips the path from `application_url` when it auto-updates dev URLs ([Shopify/cli#3464](https://github.com/Shopify/cli/issues/3464)). With `true`, a dev preview overrides `/plugin_settings` to `/` and Admin embeds the host root instead of the settings page. Keep it `false` and set the Partner active version URL yourself.
4. App Home (`app-home/index.html`) iframes `{HOST_BASE_URL}/plugin_settings?shop=...`. If the shop is not Connected, App Home shows Connect on that page. If it is Connected, App Home shows Disconnect only.
5. App Bridge `idToken()` appends `shopify_session_token`. The dummy host verifies HS256 through Oauth, then the Shopify plugin parses `dest` / `iss` and records the install.

Serve `app-home/` as the embedded application URL, or copy those two files behind the CLI web target you already use.

### Session cookies in the App Home iframe

App Home loads the dummy host in a cross-site iframe (`admin.shopify.com` → your tunnel or production origin). The dummy sets the Rails session cookie to `SameSite=None` with `Secure` on HTTPS (or when `config.force_ssl` is on). Plain `http://localhost` keeps `SameSite=Lax` without `Secure` for top-level dev. Top-level login in the browser was only a workaround when the session stayed `Lax` and would not stick inside the iframe.

## Merchant path

1. Install the Shopify plugin from Partner Dashboard or `shopify app dev`.
2. Open App Home. That is Installed, not Connected. The iframe lands on `/plugin_settings` and shows Connect until you Connect.
3. Sign in on the dummy host if asked (`admin@admin.com` / `Password`).
4. Click Connect. App Home then shows Shopify plugin settings with Disconnect. Disconnect is a host soft disconnect. It does not uninstall the Shopify plugin.

`app/uninstalled` posts to `{HOST_BASE_URL}/shopify_plugin_demo/uninstall`. The dummy checks `X-Shopify-Hmac-Sha256` against the raw body with the Registered App session token secret (the Partner API secret). A valid stamp then calls `ShopifyInstall.remove`. A missing or forged stamp returns 401 and leaves the install row.

## Theme extension

`extensions/recording-studio-theme` is a Liquid block. Pick a page by title. Host URL and storefront token come from app metafields written on Connect. Shop comes from `shop.permanent_domain`. The block loads `{host}/shopify_plugin_demo/storefront/embed.js` and mounts Embeddable HTML plus FlatPack CSS and Stimulus. Do not iframe the host there.

`shopify.extension.toml` stays in the [theme app extension](https://shopify.dev/docs/apps/build/online-store/theme-app-extensions/configuration) shape: top-level `name`, `type = "theme"`, `handle`, and the Partner-assigned `uid`. Do not wrap it in `[[extensions]]`. Do not replace `uid` with the handle slug. The committed uid is `81c9fe3d-05be-b07e-ea88-ffb54a87ed43140e385c`. Keep it so the next checkout updates the same extension.

### Show the block in Edit theme

Do this on your Mac after you pull. Do not run `shopify app deploy` from a Cloud Agent. Do not change Partner live App URLs for this step.

1. In Partner Dashboard or Dev Dashboard, turn on **Development store preview** for this app if that control is still there. You have to do this in Partner UI. The repo cannot.
2. From `shopify/`, stop any running CLI, then start `shopify app dev --no-update` against store `plugin-test-74hpuu5t`.
3. Wait until the CLI says the theme extension bundled and the theme extension server is ready.
4. In Admin for that store, open **Online Store → Themes**, then **Edit theme** on the current theme `test-data`.
5. Choose **Add section → Apps**. You should see **Shopify plugin** (block schema name) under the **Recording Studio** theme extension.

A Partner deploy already assigned this extension uid. Do not run `shopify app deploy` from a Cloud Agent. After you pull, restart `shopify app dev --no-update` so the CLI reuses that uid.

Connect writes those metafields on the **app installation** when the App Home session token is present on the Connect POST. Values must read back before the host shows “Storefront metafields synced.” Connect does not create metafield definitions with `APP_INSTALLATION` on Admin API 2025-01.

The theme block reads installation values with reserved-namespace Liquid syntax, for example `app.metafields["$app:recording_studio"]["host_base_url"].value`. Use bracket notation for both the `$app:recording_studio` namespace and the writer keys (`host_base_url`, `storefront_token`, `pages`). Dot notation on `recording_studio` or on the keys alone does not match what Connect writes. The block root includes `block.shopify_attributes` so the theme editor can select the app block.

The block loads `embed.js` with `defer`. The host mount script polls for `#recording-studio-<block id>` before injecting HTML. FlatPack CSS and a classic `embed_boot.js` load as Liquid `<link>` and `<script>` tags on the public host, not as dynamically created importmap or module tags. Shopify storefront CSP blocked those injections after HTML paint.

## Partner smoke on development-store-kwcwfmcz

Marikit runs this on the Partner store tomorrow. Do not run `shopify app deploy` from a Cloud Agent.

Set these on the dummy host before you start.

- `HOST_BASE_URL` is the public dummy origin the CLI tunnel will call.
- `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID` is the Oauth Registered App id (`rsoauth_oc_…`).
- That Registered App session token secret is the Partner app API secret. HMAC and session tokens share it.

### Install and Connect

1. Boot the dummy (`cd test/dummy && bin/dev`).
2. From `shopify/`, run `shopify app dev --no-update` and install on `development-store-kwcwfmcz`.
3. Open App Home. You should see Connect on `/plugin_settings`. Installed is not Connected.
4. Sign in if asked (`admin@admin.com` / `Password`). Click Connect. App Home stays on `/plugin_settings` for that shop. You should see Connected and Disconnect.

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
