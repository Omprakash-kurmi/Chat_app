class AddOwnerWorkflowTable < ActiveRecord::Migration[7.2]
  def up
    # --- listing verification ---
    # add_column :properties, :status, :integer, null: false, default: 0   # 0 pending, 1 published, 2 rejected, 3 closed
    # add_column :properties, :rejection_reason, :text
    # add_column :properties, :verified_at, :datetime
    # add_index  :properties, :status

    # Listings that already exist were visible before this feature, so keep them published.
    execute "UPDATE properties SET status = 1, verified_at = NOW()"

    # --- inquiries (customer -> owner) ---
    create_table :inquiries do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer  :status, null: false, default: 0   # 0 pending, 1 accepted, 2 rejected, 3 withdrawn, 4 deal_done
      t.text     :message, null: false
      t.string   :phone
      t.text     :owner_note
      t.datetime :responded_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :inquiries, [ :property_id, :status ]
    # a customer can have only one open (pending/accepted) inquiry per property
    add_index :inquiries, [ :property_id, :user_id ], unique: true, where: "status IN (0, 1)",
              name: "index_inquiries_one_open_per_user"

    # --- chat inside an inquiry ---
    create_table :inquiry_messages do |t|
      t.references :inquiry, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end

    # --- property visits ---
    create_table :visits do |t|
      t.references :inquiry, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.references :proposed_by, null: false, foreign_key: { to_table: :users }
      t.datetime :scheduled_at, null: false
      t.integer  :status, null: false, default: 0   # 0 requested, 1 confirmed, 2 declined, 3 cancelled, 4 completed
      t.string   :note
      t.timestamps
    end
    add_index :visits, [ :property_id, :scheduled_at ]
  end

  def down
    drop_table :visits
    drop_table :inquiry_messages
    drop_table :inquiries
    remove_index :properties, :status
    remove_column :properties, :verified_at
    remove_column :properties, :rejection_reason
    remove_column :properties, :status
  end
end
