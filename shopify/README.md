# Shopify CLI shell

BowerBird uses Shopify CLI for this channel. This folder is the thin app: TOML, App Home iframe, uninstall webhook, and a theme extension mount. It is not a React Admin rebuild.

## Point App Home at the dummy host

1. Boot the dummy host (`cd test/dummy && bin/dev`).
2. Set `HOST_BASE_URL` to that origin (for example `http://localhost:3000`).
3. Put the same origin in `shopify.app.toml` `application_url` when you run `shopify app dev`.
4. App Home (`app-home/index.html`) iframes `{HOST_BASE_URL}/shopify_plugin_demo/connect?shop=...`.
5. App Bridge `idToken()` appends `shopify_session_token`. The host does not verify HS256 yet. That work lands in RecordingStudio Oauth.

Serve `app-home/` as the embedded application URL, or copy those two files behind the CLI web target you already use.

## Merchant path

1. Install the Shopify plugin from Partner Dashboard or `shopify app dev`.
2. Open App Home. That is Installed, not Connected.
3. Sign in on the dummy host if asked (`admin@admin.com` / `Password`).
4. Click Connect.

`app/uninstalled` posts to `{HOST_BASE_URL}/shopify_plugin_demo/uninstall` and clears the stub connection row.

## Theme extension

`extensions/recording-studio-theme` is a Liquid block. Set host URL and page recording id. Storefront uses browser-payload plus SDK. Do not iframe the host there.
