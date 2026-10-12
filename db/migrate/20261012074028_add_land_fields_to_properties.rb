class AddLandFieldsToProperties < ActiveRecord::Migration[7.2]
  def change
    add_column :properties, :land_type, :integer
    add_column :properties, :land_area, :decimal, precision: 14, scale: 2
    add_column :properties, :area_unit, :string, default: "sqft", null: false
    add_column :properties, :plot_length, :decimal, precision: 8, scale: 2
    add_column :properties, :plot_width, :decimal, precision: 8, scale: 2
    add_column :properties, :facing, :string
    add_column :properties, :road_width_ft, :integer
    add_column :properties, :boundary_wall, :boolean, default: false, null: false
    add_column :properties, :corner_plot, :boolean, default: false, null: false
    add_column :properties, :ownership_type, :string
    add_column :properties, :approval_authority, :string
    add_index  :properties, :land_type
  end
end
