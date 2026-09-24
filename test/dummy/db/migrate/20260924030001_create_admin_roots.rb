# frozen_string_literal: true

class CreateAdminRoots < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_roots, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.timestamps
    end
  end
end
