ActiveAdmin.register Rsvp do
  permit_params :status, :event_id, :user_id

  index do
    selectable_column
    id_column
    column :event
    column :user
    column :status
    column :created_at
    actions
  end

  filter :status
  filter :event
  filter :user
  filter :created_at
end
