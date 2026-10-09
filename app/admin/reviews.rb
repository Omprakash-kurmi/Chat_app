ActiveAdmin.register Review do
  permit_params :rating, :title, :comment
  index do
    selectable_column
    id_column
    column :property
    column :user
    column :rating
    column :comment
    column :created_at
    actions
  end
  filter :rating
  filter :property
end
