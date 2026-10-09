class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string  :title
      t.text    :comment
      t.timestamps
    end
    add_index :reviews, %i[user_id property_id], unique: true
  end
end
