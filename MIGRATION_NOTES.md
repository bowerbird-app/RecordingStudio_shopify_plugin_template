# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.5.0`)
- Accessible dummy tag `v0.15.0` (access constraint/rule migrations from `0.14.0` installed in `test/dummy`) and Root Switchable dummy tag `v0.9.0`
- Metrics dummy tag `v0.2.0` (required by Root Switchable `v0.7+`) and Cache dummy tag `v0.5.0` (required by Oauth `0.9+`, Users `0.21+`, Root Switchable `0.9+`)
- Attachable dummy tag `v0.15.0` (libraries/placements migrations already installed in `test/dummy`; i18n wave 2 has no new migration)
- FlatPack dummy tag `v0.1.213` (required by Attachable `v0.12+`)
- Public RubyGems and GitHub access for dependency installation

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
