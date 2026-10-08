class AddGoogleLoginToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :provider,   :string unless column_exists?(:users, :provider)
    add_column :users, :uid,        :string unless column_exists?(:users, :uid)
    add_column :users, :avatar_url, :string unless column_exists?(:users, :avatar_url)
    add_index  :users, %i[provider uid], unique: true unless index_exists?(:users, %i[provider uid])
  end
end
