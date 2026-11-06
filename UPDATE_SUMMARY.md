# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", "~> 6.3"`
- Dummy GitHub tags: Recording Studio `v6.5.0`, Accessible `v0.24.2`, Root Switchable `v0.11.7`, FlatPack `v0.1.341`
- Root and dummy Rails locks both `8.1.4.1`
- Authenticated dummy layout: `recording_studio_layout { application_layout }` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
