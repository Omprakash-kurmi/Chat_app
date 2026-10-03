ActiveAdmin.register Event do
  permit_params :title, :description, :starts_at, :room_id, :user_id

  index do
    selectable_column
    id_column
    column :title
    column :room
    column :user
    column :starts_at
    column :created_at
    actions
  end

  filter :title
  filter :description
  filter :room
  filter :user
  filter :starts_at
  filter :created_at

  show do
    attributes_table do
      row :id
      row :title
      row :description
      row :room
      row :user
      row :starts_at
      row :created_at
      row :updated_at
    end
  end
end
