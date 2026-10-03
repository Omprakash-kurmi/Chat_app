ActiveAdmin.register Message do
  permit_params :content, :room_id, :user_id, :image

  index do
    selectable_column
    id_column
    column :room
    column :user
    column :content
    column :image do |message|
      image_tag(rails_storage_proxy_url(message.image.variant(resize_to_limit: [ 60, 60 ]))) if message.image.attached?
    end
    column :created_at
    actions
  end

  filter :content
  filter :room
  filter :user
  filter :created_at

  show do
    attributes_table do
      row :id
      row :room
      row :user
      row :content
      row :image do |message|
        if message.image.attached?
          image_tag(rails_storage_proxy_url(message.image.variant(resize_to_limit: [ 400, 400 ])))
        else
          status_tag("No image", class: "no")
        end
      end
      row :created_at
      row :updated_at
    end
  end
end
