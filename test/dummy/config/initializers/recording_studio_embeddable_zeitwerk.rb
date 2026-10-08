# frozen_string_literal: true

# RecordingStudio Embeddable adds its lib/ to the host autoload + eager_load
# paths. That directory is already loaded via explicit requires in
# recording_studio_embeddable.rb. Leaving it on the host Zeitwerk loader breaks
# CI eager_load (config.eager_load = ENV["CI"].present?) because:
# - version.rb defines VERSION, not Version
# - capabilities/embeddable.rb defines RecordingStudio::Capabilities::Embeddable
# Ignore the gem lib so eager load only walks constants that match the tree.
if defined?(RecordingStudioEmbeddable::Engine)
  embeddable_lib = RecordingStudioEmbeddable::Engine.root.join("lib")
  Rails.autoloaders.main.ignore(embeddable_lib) if embeddable_lib.directory?
end
