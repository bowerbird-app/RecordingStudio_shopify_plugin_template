# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @page_recordings = page_recordings_scope
  end

  def show
    @page_recording = find_page_recording
    @page = @page_recording.recordable
  end

  def embed_preview
    @page_recording = find_page_recording
    page = @page_recording.recordable
    @page = page
    @parent_recordable = page
    render template: "pages/embed", layout: "embed_preview"
  end

  private

  def page_recordings_scope
    RecordingStudio::Recording
      .includes(:recordable)
      .where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
      .where(recordable_type: "Page")
      .order(:created_at, :id)
  end

  def find_page_recording
    page_recordings_scope.find(params[:id])
  end
end
