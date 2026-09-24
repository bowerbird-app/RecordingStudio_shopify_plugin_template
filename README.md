# Recording Studio Shopify plugin

This repo is the Recording Studio Shopify plugin channel. The dummy host in `test/dummy/` is a Rails 8.1 Recording Studio app. The Shopify CLI shell in `shopify/` is a thin Liquid and TOML app. They do not share a process.

Call it Shopify plugin in product copy.

Merchants Install the Shopify plugin in Admin, then Connect on the dummy host. Installed is not Connected.

## Dummy host

From `test/dummy/`:

```bash
bundle install
bin/rails db:setup
bin/dev
```

Open http://localhost:3000 and sign in at `/users/sign_in`.

| Field | Value |
| --- | --- |
| Email | admin@admin.com |
| Password | Password |

Useful routes:

- `/` home
- `/shopify_plugin_demo/connect` Connect and Connected (iframe target for App Home)
- `/pages` page ids for the theme extension
- `/shopify_plugin_demo/storefront/embed.js` scoped storefront browser-payload mount (HTML/JS, not an iframe)
- `/recording_studio_api/apis/shopify_plugin_demo/v1/pages/:id/actions/embed` named API browser payload (bearer token, not the storefront)
- `POST /shopify_plugin_demo/uninstall` Partner `app/uninstalled` stub

Named API key is `shopify_plugin_demo`. Page enables Embeddable `:embed`. The storefront theme block loads `/shopify_plugin_demo/storefront/embed.js` with a scoped token. Do not iframe the host on the storefront. Do not send the Admin session token on the storefront.

Connect on this host calls RecordingStudio Oauth `verify_session_token`, then the Shopify plugin parses `dest` / `iss` and upserts `recording_studio_oauth_external_installs`. Do not add `shopify_*` columns to `users` or `workspaces`. Installed is not Connected.

White-label strings live in `test/dummy/lib/shopify_plugin_demo/product_config.rb` (`Shopify plugin` / `Shopify Template Demo`).

Dummy gem pins match the WordPress dummy where they apply: RecordingStudio `v4.2.0`, Accessible `v0.9.1`, API `v0.5.6`, Embeddable `v0.2.1`, Oauth `v0.5.3`, Admin `v2.0.2`, Users `v0.11.0`, FlatPack `v0.1.190`.

Set `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID` to the Connect Registered App id (`rsoauth_oc_…`). The Partner app client id is JWT `aud` on Token verification, not that id.

## Shopify CLI

BowerBird uses Shopify CLI. See `shopify/README.md`.

1. Set `HOST_BASE_URL` to the dummy origin.
2. Serve `shopify/app-home/` as the embedded App Home.
3. App Home iframes `{HOST_BASE_URL}/shopify_plugin_demo/connect?shop=...`.
4. App Bridge `idToken()` is appended as `shopify_session_token`. The host verifies HS256 through Oauth, then parses Shopify claims.
5. Theme app extension `shopify/extensions/recording-studio-theme` sets host URL, page id, and storefront token. Shop comes from the storefront.

```bash
cd shopify
# shopify app dev  # after Partner app credentials
```

## Tests

Gem suite:

```bash
bundle exec rake test
```

Dummy suite (needs PostgreSQL):

```bash
bundle exec rake test:dummy
```

Both:

```bash
bundle exec rake test:all
```
