class CreateReviewVotes < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :helpful_count,     :integer, default: 0, null: false
    add_column :reviews, :not_helpful_count, :integer, default: 0, null: false

    create_table :review_votes do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :review, null: false, foreign_key: true
      t.boolean :helpful, null: false, default: true
      t.timestamps
    end
    add_index :review_votes, %i[user_id review_id], unique: true
  end
end
