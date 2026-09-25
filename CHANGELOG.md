# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Shopify token exchange uses the IETF `grant_type` URN. `ShopifyAdminHttp` sends `Accept: application/json` and turns OAuth HTML or JSON failures into readable errors instead of JSON parse errors on `<!DOCTYPE`.
- Storefront metafields write on the app installation (what theme `app.metafields` reads). Connect checks GraphQL errors, rejects hollow `metafieldsSet`, and read-backs `host_base_url` and `storefront_token` before reporting sync ok. Connect does not call `metafieldDefinitionCreate` with `APP_INSTALLATION` (invalid on Admin API 2025-01).

### Changed
- Dummy App Home iframe lands on `/plugin_settings`. Not Connected redirects to Connect. Connected shows Disconnect only (host soft disconnect).
- `shopify.app.toml` `application_url` documents `https://example.com/plugin_settings`. Partner Dev Dashboard App URL should use `https://<HOST>/plugin_settings`.

## [0.3.4] - 2026-09-25

### Added
- Dummy Pages table plus storefront preview. Getting Started renders a FlatPack card and tooltip. Carousel is a seeded page with FlatPack carousel slides.
- Storefront `embed.js` injects FlatPack CSS, an import map, and `embed_boot.js` so Card, Tooltip, and Carousel run on Shopify.
- After Connect, the host mints a shop-scoped storefront token and writes app metafields for host URL, token, and `{id, title}` pages.
- Connect flash names a storefront metafield failure. Bind can succeed while metafields do not. Open Connect from App Home when the session token is missing.

### Changed
- Theme block settings are Page titles only. Host URL and storefront token come from app metafields. Shop still comes from the store.
- `ShopifyStorefrontEmbed.mint` is shop-scoped. Page is chosen in the theme block and sent as `page_id`.

### Upgrade notes
- Connect on the dummy host while App Home still has a session token so metafields can write. Merchants pick a page title in the theme editor. They do not paste host or token.
- If Connect binds without a session token, the shop is Connected and metafields stay empty. The host shows an alert. Open Connect from App Home and click Connect again.
- Theme schema page options match seeded titles (`Getting Started`, `Carousel`). Add an option when you seed another page.
- Call `ShopifyStorefrontEmbed.mint(shop_domain:, secret:)` without a page id.

## [0.3.3] - 2026-09-24

### Added
- `ShopifyWebhookHmac` checks Shopify `X-Shopify-Hmac-Sha256` against the raw POST body.
- Dummy `POST /shopify_plugin_demo/uninstall` rejects a missing or forged HMAC with 401, then runs `ShopifyInstall.remove` only when the stamp matches.
- Partner smoke checklist in `shopify/README.md` for `development-store-kwcwfmcz`.

### Upgrade notes
- Point the dummy Registered App session token secret at the Partner app API secret. HMAC uses that secret. Do not add a second secret store.
- Keep `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID` set to that Registered App id so uninstall can look the secret up.

## [0.3.2] - 2026-09-24

### Added
- Scoped storefront embed URL. Theme Liquid loads Embeddable browser-payload HTML and JS. It does not iframe the host.
- `ShopifyStorefrontEmbed` mints and checks an HMAC token for shop plus page. Entitlement still uses Oauth install plus Connect. Admin session cookies do not count on the storefront.
- Dummy `GET /shopify_plugin_demo/storefront/embed.js` (and `.json`) returns the payload with public cache headers. Failed checks are 404 and are not cached.
- Theme editor setup copy stays in `request.design_mode`. Shoppers see a short empty line if the mount fails.

### Upgrade notes
- In the theme editor, set Host URL, Page id, and Storefront token. Shop is `shop.permanent_domain`.
- Mint a token after Connect with `ShopifyStorefrontEmbed.mint` and `ShopifyStorefrontEmbed.secret_for` on the Registered App. Paste that token into the theme block.
- Production CDN can sit in front of the scoped URL later. This release only sets `Cache-Control`.

## [0.3.1] - 2026-09-24

### Changed
- Dummy host pins RecordingStudio Oauth `v0.5.3`.
- App Home session tokens are verified on the host. Oauth checks HS256, `aud`, `exp`, and `nbf`. The Shopify plugin parses `dest` and `iss`, then upserts `recording_studio_oauth_external_installs`.

### Removed
- Temporary `shopify_plugin_demo_connections` table. Shop mapping lives on Oauth external installs.

### Upgrade notes
- Point dummy Gemfile Oauth at tag `v0.5.3`, then `bundle install` and `bin/rails db:prepare` so Oauth's session-token and external-install migration can run.
- Create a Registered App (`rsoauth_oc_…`) for Connect. Turn on Token verification. Set Channel to `shopify`, Who the token is for to the Partner app client id (`aud`), and Session token secret to the Partner app secret.
- Set `SHOPIFY_PLUGIN_REGISTERED_APP_CLIENT_ID` to that Registered App id.
- Installed still is not Connected. A verified session token can write an install before anyone clicks Connect.
- `ShopifyInstall.bind` only connects an install that `record_from_session_token` already wrote. `ShopifyInstall.remove` needs `client` or `client_id` and never deletes every app's row for a shop.

## [0.3.0] - 2026-09-24

### Changed
- Renamed the engine to `recording_studio_shopify_plugin_template`.
- Dummy host is the Shopify plugin demo. Named API is `shopify_plugin_demo`.

### Added
- Dummy pins for API, Embeddable, Oauth, Admin, Users, and related boot gems, matching the WordPress dummy tags.
- Connect / Connected / Disconnect FlatPack screen, iframe-able from Shopify Admin, plus CSP `frame-ancestors`.
- Temporary `shopify_plugin_demo_connections` table for demo Connect. Replace with Oauth generic installs later.
- `shopify/` CLI shell: App Home iframe, uninstall webhook stub, theme extension mount.

### Upgrade notes
- Point dummy Gemfile pins at the versions in `test/dummy/Gemfile`, then `bundle install` and `bin/rails db:prepare`.
- Set `HOST_BASE_URL` when pointing Shopify App Home at the dummy Connect URL.


## [0.2.2] - 2026-09-11

### Changed
- Gemspec `recording_studio` floor `~> 4.1` → `~> 4.2` so copied addons match Accessible 0.7+.
- Dummy Accessible tag `v0.6.0` → `v0.9.1`; FlatPack tag `v0.1.133` → `v0.1.177`. Recording Studio stays `v4.2.0`; Root Switchable stays `v0.5.0`.
- Root `Gemfile.lock` Rails `8.1.1` → `8.1.3.1` (with `json` `2.21.2`, `mail` `2.9.1`, `nokogiri` `1.19.4`) to match the dummy host lock and Active Storage CVE-2026-66066.
- Extra Cloud Agent skills now come from the plugin catalog (`skill-sources.json`) instead of a hardcoded extra URL. A missing or invalid catalog is skipped so Recording Studio skills still fetch. Failures still warn and exit 0.
- Docs and pin tests no longer mention `recording_studio/v3.0.0`, FlatPack `v0.1.133`, or Accessible `v0.6.0`.

### Added
- After skills, the Cloud Agent fetch hook lists plugin `*.mdc` rules from `RecordingStudio_cursor_plugin` into `.cursor/rules/` (gitignored, not packaged). A missing rules directory warns and skips. Failures still exit 0.
- Cloud Agent skill-fetch hook so copied addons load Recording Studio skills at Build time. `.cursor/environment.json` names the environment `recording-studio-gem-template`. `install` is `.cursor/install.sh`, which runs `.cursor/fetch-skills.sh` after provisioning. `snapshot` is omitted on purpose so Builds run install instead of reusing a laptop Personal snapshot. The script lists `recording-studio-*` skill ids from the public GitHub contents API and writes each `SKILL.md` into `.cursor/skills/` (gitignored, not packaged). Failures warn and still exit 0.
- Dummy Accessible migration for `depends_on_recording_id` (Accessible 0.8+).

### Upgrade notes
- Bump addon gemspecs to `spec.add_dependency "recording_studio", "~> 4.2"`.
- Point host/dummy Gemfiles at Accessible `v0.9.1` and FlatPack `v0.1.177` (Recording Studio tag stays `v4.2.0`).
- Run `bin/rails generate recording_studio_accessible:migrations` then `bin/rails db:migrate`. Do not hand-edit Accessible tables.
- Rebuild Tailwind after the FlatPack tag bump: `bin/rails tailwindcss:build`.
- Align root gem-suite `Gemfile.lock` Rails to `8.1.3.1` if it is still on `8.1.1`.

## [0.2.1] - 2026-09-01

### Added
- Full Cloud Agent development environment. `.cursor/install.sh` now provisions the whole stack at Build time on Cursor's default image — Ruby (pinned by `.ruby-version`), PostgreSQL 16, gem dependencies for both the gem and the dummy host app, the seeded dummy database, and compiled Tailwind/FlatPack CSS — then runs the existing `.cursor/fetch-skills.sh`. `snapshot` stays omitted so Builds run `install` as before.
- `.cursor/start.sh` per-boot hook that starts PostgreSQL and waits for readiness.
- `.cursor/environment.json` now declares `start` plus `rails-server` and `tailwind-watch` terminals and exposes port 3000, so a fresh Cloud Agent boots straight into a running, signed-in-ready dummy app.

### Notes
- The install script is idempotent; running it against a warm machine reuses the existing Ruby, packages, and gems.
- No gem runtime code changed. `.cursor/` files are excluded from the packaged gem.

## [0.2.0] - 2026-08-21

New addons copied from this template are born on Recording Studio 4.x.

### Added
- Gemspec dependency `recording_studio`, `~> 4.1`
- Dummy host wiring for Accessible (`enable_capability(:accessible, on: Workspace)`) and an opt-in `RecordingStudio::Capabilities::Example.to` mixin. `.to` wraps core 4.2.0 `include_for` (not a fourth verb, and not a raw `enable_capability` / `set_capability_options` path). Installing the gem does not enable the mixin globally; only dummy Workspace opts in.
- `bin/rename_gem` leftover-identity rewrite/verification for README, homepage, and changelog URLs that still say `RecordingStudioShopifyPluginTemplate` or point at `bowerbird-app/recording_studio_shopify_plugin_template`

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated layout is Recording Studio's default layout plus FlatPack CSS/JS; Devise keeps its own sign-in layout
- Dummy app security pins: Rails `8.1.3.1`, `json` `2.21.2`, `mail` `2.9.1`, Brakeman `8.0.6`
- Require `RecordingStudio::Hooks` and `RecordingStudio::Services::BaseService` from core instead of shipping copies

### Removed
- Copied `lib/recording_studio_shopify_plugin_template/hooks.rb` and `lib/recording_studio_shopify_plugin_template/services/base_service.rb`
- Product-shipped `ExampleService`
- Custom `flat_pack_sidebar` authenticated shell

### Upgrade notes
- Point dummy or host Gemfiles at Recording Studio `v4.2.0` (not `recording_studio/v3.0.0`)
- Add `spec.add_dependency "recording_studio", "~> 4.1"` to addon gemspecs
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Delete any copied Hooks or BaseService files and require the core classes
- Keep recordable declarations; they are required, not a v3-only concern
- If Accessible is bundled, call `RecordingStudio.enable_capability(:accessible, on: Workspace)` (or your root type)

## [0.1.2] - 2026-07-21

### Changed
- Bumped the dummy app FlatPack dependency from `v0.1.33` to `v0.1.129`

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/compare/v0.3.3...HEAD
[0.3.3]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.3.3
[0.3.2]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.3.2
[0.3.1]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.3.1
[0.3.0]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.3.0
[0.2.2]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.2.2
[0.2.1]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/recording_studio_shopify_plugin_template/releases/tag/v0.1.0
