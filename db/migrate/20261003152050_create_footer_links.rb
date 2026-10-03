class CreateFooterLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :footer_links do |t|
      t.references :footer_column, null: false, foreign_key: true
      t.string :label
      t.string :url
      t.integer :position

      t.timestamps
    end
  end
end
