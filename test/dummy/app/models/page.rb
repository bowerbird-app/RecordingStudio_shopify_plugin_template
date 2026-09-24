class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: [ "Workspace", "Folder" ]

  if defined?(RecordingStudioEmbeddable)
    include RecordingStudio::Capabilities::Embeddable.to(
      renderer: "pages/embed",
      require_publishable: false
    )
  end
end
