class ApplicationController < ActionController::Base
  include RecordingStudio::RootSwitchable::ControllerSupport
  recording_studio_layout { application_layout }

  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_actor

  private

  def application_layout
    devise_controller? ? "application" : "host"
  end

  def set_current_actor
    Current.actor = current_user
  end
end
