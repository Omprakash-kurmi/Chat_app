class ProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :full_name,    :string unless (%w[full_name name username] & column_names_for(:users)).any?
    add_column :users, :phone,        :string unless column_exists?(:users, :phone)
    add_column :users, :company_name, :string unless column_exists?(:users, :company_name)
    add_column :users, :gstin,        :string unless column_exists?(:users, :gstin)
    add_column :users, :address,      :string unless column_exists?(:users, :address)
    add_column :users, :city,         :string unless column_exists?(:users, :city)
    add_column :users, :state,        :string unless column_exists?(:users, :state)
    add_column :users, :pincode,      :string unless column_exists?(:users, :pincode)
    add_column :users, :user_code,    :string unless column_exists?(:users, :user_code)
  end

  private

  def column_names_for(table)
    connection.columns(table).map(&:name)
  end
end
