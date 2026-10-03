class AddUniqueIndexToRsvps < ActiveRecord::Migration[7.2]
  def change
    add_index :rsvps, [:event_id, :user_id], unique: true
  end
end
