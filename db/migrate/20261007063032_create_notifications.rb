class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.bigint "user_id", null: false
      t.string "kind", default: "general", null: false
      t.string "title", null: false
      t.text "body"
      t.string "path"
      t.string "dedupe_key"
      t.datetime "read_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "user_id", "dedupe_key" ], name: "index_notifications_on_user_and_dedupe_key", unique: true, where: "(dedupe_key IS NOT NULL)"
      t.index [ "user_id", "read_at" ], name: "index_notifications_on_user_id_and_read_at"
      t.index [ "user_id" ], name: "index_notifications_on_user_id"
    end
  end
end
