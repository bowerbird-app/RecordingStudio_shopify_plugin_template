# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyPluginDemo::InstallContext

  def index
    @shop_domain = resolved_shop_domain
    record_install_from_session_token
    @install = find_install
    @connected = @install&.connected?
  end
end
