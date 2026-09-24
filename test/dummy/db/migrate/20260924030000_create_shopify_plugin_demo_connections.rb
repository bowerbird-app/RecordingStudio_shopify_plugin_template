# frozen_string_literal: true

class CreateShopifyPluginDemoConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :shopify_plugin_demo_connections, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :shop_domain, null: false
      t.string :status, null: false, default: "installed"
      t.datetime :connected_at
      t.timestamps
    end

    add_index :shopify_plugin_demo_connections, :shop_domain, unique: true
  end
end
