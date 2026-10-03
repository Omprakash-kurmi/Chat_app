class CreateSocialLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :social_links do |t|
      t.string :platform
      t.string :url
      t.integer :position

      t.timestamps
    end
  end
end
