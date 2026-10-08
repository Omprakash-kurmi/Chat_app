ActiveAdmin.register User do
  permit_params :name,
                :email,
                :password,
                :password_confirmation,
                :bio,
                :role,
                :admin,
                :avatar

  scope :all, default: true
  scope("Customers") { |users| users.where(role: User.roles[:customer]) }
  scope("Vendors")   { |users| users.where(role: User.roles[:vendor]) }
  scope("Admins")    { |users| users.where(admin: true) }
  scope("Google users") { |users| users.where(provider: "google_oauth2") }

  filter :id
  filter :name
  filter :email
  # filter :role, as: :select, collection: User.roles.keys.map { |role| [role.humanize, role] }
  filter :provider, label: "Signed up with", as: :select,
                    collection: { "Google" => "google_oauth2" }
  filter :admin
  filter :created_at
  filter :updated_at

  index do
    selectable_column

    id_column

    column :avatar do |user|
      src = user.avatar.attached? ? url_for(user.avatar) : user.avatar_url.presence
      if src
        image_tag(
          src,
          width: 50,
          height: 50,
          style: "border-radius: 50%; object-fit: cover;",
          referrerpolicy: "no-referrer"
        )
      else
        status_tag "No Avatar"
      end
    end

    column :name do |user|
      link_to user.display_name, admin_user_path(user)
    end

    column :email

    column "Signed up with" do |user|
      user.provider.present? ? status_tag("Google", class: "ok") : status_tag("Email")
    end

    column :role do |user|
      status_tag user.role&.humanize
    end

    column :admin do |user|
      status_tag(user.admin? ? "Yes" : "No")
    end

    column :properties do |user|
      link_to(
        user.properties.count,
        admin_properties_path(q: { user_id_eq: user.id })
      )
    end

    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id

      row :avatar do |user|
        src = user.avatar.attached? ? url_for(user.avatar) : user.avatar_url.presence
        if src
          image_tag(
            src,
            width: 120,
            height: 120,
            style: "border-radius: 50%; object-fit: cover;",
            referrerpolicy: "no-referrer"
          )
        else
          status_tag "No Avatar"
        end
      end

      row :name
      row :display_name
      row :email

      row "Signed up with" do |user|
        user.provider.present? ? status_tag("Google", class: "ok") : status_tag("Email")
      end

      row :role

      row :admin do |user|
        status_tag(user.admin? ? "Yes" : "No")
      end

      row :bio

      row :properties do |user|
        if user.properties.any?
          user.properties.map do |property|
            link_to property.title, admin_property_path(property)
          end.join(", ").html_safe
        else
          "No properties"
        end
      end

      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors

    f.inputs "User Information" do
      f.input :name
      f.input :email
      f.input :role,
              as: :select,
              collection: User.roles.keys.map { |role| [ role.humanize, role ] }

      f.input :bio
      f.input :admin
    end

    f.inputs "Authentication" do
      f.input :password,
              hint: "Leave blank if you don't want to change the password."

      f.input :password_confirmation
    end

    f.inputs "Avatar" do
      f.input :avatar, as: :file

      if f.object.avatar.attached?
        para do
          image_tag(
            url_for(f.object.avatar),
            width: 100,
            height: 100,
            style: "border-radius: 50%; object-fit: cover;"
          )
        end
      end
    end

    f.actions
  end

  member_action :make_vendor, method: :put do
    resource.update!(role: :vendor)

    redirect_to(
      resource_path(resource),
      notice: "#{resource.display_name} is now a vendor."
    )
  end

  member_action :make_customer, method: :put do
    resource.update!(role: :customer)

    redirect_to(
      resource_path(resource),
      notice: "#{resource.display_name} is now a customer."
    )
  end

  member_action :toggle_admin, method: :put do
    resource.update!(admin: !resource.admin?)

    redirect_to(
      resource_path(resource),
      notice: "#{resource.display_name}'s admin status has been updated."
    )
  end

  action_item :make_vendor,
              only: :show,
              if: proc { resource.customer? } do
    link_to(
      "Make Vendor",
      make_vendor_admin_user_path(resource),
      method: :put
    )
  end

  action_item :make_customer,
              only: :show,
              if: proc { resource.vendor? } do
    link_to(
      "Make Customer",
      make_customer_admin_user_path(resource),
      method: :put
    )
  end

  action_item :toggle_admin,
              only: :show do
    link_to(
      resource.admin? ? "Remove Admin" : "Make Admin",
      toggle_admin_admin_user_path(resource),
      method: :put
    )
  end

  batch_action :make_vendors do |ids|
    User.where(id: ids).update_all(role: User.roles[:vendor])

    redirect_to(
      collection_path,
      notice: "#{ids.size} user(s) changed to vendor."
    )
  end

  batch_action :make_customers do |ids|
    User.where(id: ids).update_all(role: User.roles[:customer])

    redirect_to(
      collection_path,
      notice: "#{ids.size} user(s) changed to customer."
    )
  end

  batch_action :make_admins do |ids|
    User.where(id: ids).update_all(admin: true)

    redirect_to(
      collection_path,
      notice: "#{ids.size} user(s) made admin."
    )
  end

  controller do
    def scoped_collection
      super.includes(:properties)
    end
  end
end
