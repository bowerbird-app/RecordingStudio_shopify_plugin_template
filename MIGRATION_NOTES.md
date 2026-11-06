# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer (root and dummy lockfiles pin 8.1.4.1; rack `>= 3.2.8`, nokogiri `>= 1.19.5`, loofah `>= 2.25.3`, rails-html-sanitizer `>= 1.7.2`; dummy net-ssh `>= 7.3.8`; view_component `>= 4.14.0`)
- Recording Studio 6.x (`~> 6.3` in the gemspec; dummy GitHub tag `v6.5.0`; English fallback via `RecordingStudio.t`; dummy uses `recording_studio_layout` and `config.allow_unauthorized_writes = true`)
- Accessible dummy tag `v0.24.2` and Root Switchable dummy tag `v0.11.7` (needs Recording Studio `>= 6.3` and FlatPack `>= 0.1.341`)
- Metrics dummy tag `v0.7.3` (Oauth `0.21.3` needs `>= 0.3`; Logs `0.7.4` needs `>= 0.6.1`) and Cache dummy tag `v0.6.3` (Embeddable `0.15.3` needs `~> 0.6`)
- API dummy tag `v0.17.1` (Oauth `0.21.3` allows API `< 0.18`) and Oauth dummy tag `v0.21.3`
- Admin dummy tag `v2.9.3` (needs Recording Studio `>= 6.3`, Logs, and FlatPack `>= 0.1.341`)
- Logs dummy tag `v0.7.4` (Admin `2.9.3` / API `0.17.1` / Embeddable `0.15.3`)
- Trashable dummy tag `v0.12.3` with `require: false` (query helpers only)
- Attachable dummy tag `v0.22.1` (libraries/placements migrations already installed in `test/dummy`)
- Site Settings dummy tag `v0.5.5`
- FlatPack dummy tag `v0.1.341` (allows view_component `>= 4.14`, `< 5`). Dummy does not prepend Card or PageNav.
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
