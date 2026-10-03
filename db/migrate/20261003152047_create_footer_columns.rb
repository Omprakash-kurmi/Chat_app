class CreateFooterColumns < ActiveRecord::Migration[7.2]
  def change
    create_table :footer_columns do |t|
      t.string :title
      t.integer :position

      t.timestamps
    end
  end
end
