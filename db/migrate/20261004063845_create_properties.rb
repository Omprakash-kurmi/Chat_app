class CreateProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.integer :listing_type
      t.integer :property_type
      t.decimal :price
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :area_sqft
      t.string :address
      t.string :city
      t.text :description
      t.string :contact_phone
      t.string :visiting_hours
      t.boolean :available

      t.timestamps
    end
  end
end
