class HomeController < ApplicationController
  def index
    return unless params[:embedded].to_s == "1"

    redirect_to plugin_settings_path(request.query_parameters)
  end
end
