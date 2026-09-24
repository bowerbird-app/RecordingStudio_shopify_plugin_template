class ApplicationController < ActionController::Base
  include RecordingStudio::RootSwitchable::ControllerSupport
  include RecordingStudio::UsesDefaultLayout

  allow_browser versions: :modern

  stale_when_importmap_changes

  layout :application_layout

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
