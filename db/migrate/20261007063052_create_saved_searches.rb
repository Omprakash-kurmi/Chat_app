class CreateSavedSearches < ActiveRecord::Migration[7.2]
  def change
    create_table :saved_searches do |t|
      t.bigint "user_id", null: false
      t.string "name", null: false
      t.string "listing_type", null: false
      t.jsonb "filters", default: {}, null: false
      t.boolean "notify", default: true, null: false
      t.datetime "last_notified_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "listing_type", "notify" ], name: "index_saved_searches_on_listing_type_and_notify"
      t.index [ "user_id" ], name: "index_saved_searches_on_user_id"
    end
  end
end
