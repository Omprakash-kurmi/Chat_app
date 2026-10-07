class CreateFavorites < ActiveRecord::Migration[7.2]
  def change
    create_table :favorites do |t|
      t.bigint "user_id", null: false
      t.bigint "property_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "property_id" ], name: "index_favorites_on_property_id"
      t.index [ "user_id", "property_id" ], name: "index_favorites_on_user_id_and_property_id", unique: true
      t.index [ "user_id" ], name: "index_favorites_on_user_id"
    end
  end
end
