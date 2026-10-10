class AddKindToInquiryMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :inquiry_messages, :kind, :string, null: false, default: "text"
  end
end
