# frozen_string_literal: true

class AddOauthSessionTokenVerifyAndDropStubConnections < ActiveRecord::Migration[8.1]
  def change
    drop_table :shopify_plugin_demo_connections, if_exists: true
  end
end
