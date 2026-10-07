class AddOwnerWorkflow < ActiveRecord::Migration[7.2]
  def up
    # --- listing verification ---
    add_column :properties, :status, :integer, null: false, default: 0 unless column_exists?(:properties, :status)
    add_column :properties, :rejection_reason, :text unless column_exists?(:properties, :rejection_reason)
    add_column :properties, :verified_at, :datetime unless column_exists?(:properties, :verified_at)
    add_index  :properties, :status unless index_exists?(:properties, :status)
    # existing listings were visible before this feature, so keep them published
    execute "UPDATE properties SET status = 1, verified_at = NOW() WHERE verified_at IS NULL AND status = 0"

    # --- inquiries ---
    unless table_exists?(:inquiries)
      create_table :inquiries do |t|
        t.references :property, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.timestamps
      end
    end
    add_reference :inquiries, :property, foreign_key: true unless column_exists?(:inquiries, :property_id)
    add_reference :inquiries, :user, foreign_key: true unless column_exists?(:inquiries, :user_id)
    add_column :inquiries, :status, :integer, null: false, default: 0 unless column_exists?(:inquiries, :status)
    add_column :inquiries, :message, :text unless column_exists?(:inquiries, :message)
    add_column :inquiries, :phone, :string unless column_exists?(:inquiries, :phone)
    add_column :inquiries, :owner_note, :text unless column_exists?(:inquiries, :owner_note)
    add_column :inquiries, :responded_at, :datetime unless column_exists?(:inquiries, :responded_at)
    add_column :inquiries, :closed_at, :datetime unless column_exists?(:inquiries, :closed_at)
    add_index :inquiries, [ :property_id, :status ] unless index_exists?(:inquiries, [ :property_id, :status ])
    unless index_name_exists?(:inquiries, "index_inquiries_one_open_per_user")
      add_index :inquiries, [ :property_id, :user_id ], unique: true, where: "status IN (0, 1)",
                name: "index_inquiries_one_open_per_user"
    end

    # --- chat inside an inquiry ---
    unless table_exists?(:inquiry_messages)
      create_table :inquiry_messages do |t|
        t.references :inquiry, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.text :body, null: false
        t.timestamps
      end
    end

    # --- property visits ---
    unless table_exists?(:visits)
      create_table :visits do |t|
        t.references :inquiry, null: false, foreign_key: true
        t.references :property, null: false, foreign_key: true
        t.references :proposed_by, null: false, foreign_key: { to_table: :users }
        t.datetime :scheduled_at, null: false
        t.integer  :status, null: false, default: 0
        t.string   :note
        t.timestamps
      end
      add_index :visits, [ :property_id, :scheduled_at ]
    end
  end

  def down
    drop_table :visits, if_exists: true
    drop_table :inquiry_messages, if_exists: true
    drop_table :inquiries, if_exists: true
    remove_index :properties, :status if index_exists?(:properties, :status)
    remove_column :properties, :verified_at if column_exists?(:properties, :verified_at)
    remove_column :properties, :rejection_reason if column_exists?(:properties, :rejection_reason)
    remove_column :properties, :status if column_exists?(:properties, :status)
  end
end
