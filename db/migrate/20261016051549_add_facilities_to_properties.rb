class AddFacilitiesToProperties < ActiveRecord::Migration[7.2]
  def change
    add_column :properties, :facilities, :string, array: true, default: [], null: false
    add_index  :properties, :facilities, using: :gin
  end
end
