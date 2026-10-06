class AddSearchFieldsToProperties < ActiveRecord::Migration[7.2]
  def change
    add_column :properties, :locality, :string
    add_column :properties, :pincode, :string
    add_column :properties, :furnishing, :integer, null: false, default: 0
    add_column :properties, :parking_spaces, :integer, null: false, default: 0
    add_column :properties, :amenities, :string, array: true, null: false, default: []
    add_column :properties, :available_from, :date
    add_column :properties, :floor_number, :integer
    add_column :properties, :total_floors, :integer
    add_column :properties, :age_years, :integer
    add_column :properties, :latitude, :decimal, precision: 10, scale: 6
    add_column :properties, :longitude, :decimal, precision: 10, scale: 6
    add_column :properties, :poster_type, :integer, null: false, default: 0
    add_column :properties, :contact_name, :string
    add_column :properties, :security_deposit, :decimal, precision: 12, scale: 2

    add_index :properties, :pincode
    add_index :properties, :locality
    add_index :properties, :amenities, using: :gin
  end
end
