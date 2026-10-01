ActiveAdmin.register Room do
  permit_params :name

  index do
    selectable_column
    id_column
    column :name
    column :created_at
    actions
  end
end