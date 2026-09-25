class HomeController < ApplicationController
  def index
    return unless params[:embedded].to_s == "1"

    query = request.query_string
    redirect_to(query.present? ? "#{plugin_settings_path}?#{query}" : plugin_settings_path)
  end
end
