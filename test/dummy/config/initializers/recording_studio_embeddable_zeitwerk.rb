# frozen_string_literal: true

if defined?(RecordingStudioEmbeddable::Engine)
  embeddable_lib = RecordingStudioEmbeddable::Engine.root.join("lib")
  Rails.autoloaders.main.ignore(embeddable_lib) if embeddable_lib.directory?
end
