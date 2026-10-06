
ActiveAdmin.register Property do
  permit_params :user_id, :title, :description, :address, :locality, :city, :pincode, :contact_phone, :price, :security_deposit, :listing_type, :property_type, :furnishing, :poster_type, :bedrooms, :bathrooms, :area_sqft, :parking_spaces, :available, :available_from, :floor_number, :total_floors, :latitude, :longitude, amenities: [], photos: [], videos: []

  # --------------------------------------------------
  # Filters
  # --------------------------------------------------
  filter :title
  filter :city
  filter :locality
  filter :pincode
  filter :listing_type, as: :select,
         collection: Property.listing_types.keys.map { |key| [key.humanize, key] }

  filter :property_type, as: :select,
         collection: Property.property_types.keys.map { |key| [key.humanize, key] }

  filter :furnishing, as: :select,
         collection: Property.furnishings.keys.map { |key| [key.humanize, key] }

  filter :poster_type, as: :select,
         collection: Property.poster_types.keys.map { |key| [key.humanize, key] }

  filter :price
  filter :bedrooms
  filter :bathrooms
  filter :area_sqft
  filter :parking_spaces
  filter :available
  filter :available_from
  filter :created_at

  # --------------------------------------------------
  # Index Page
  # --------------------------------------------------
  index do
    selectable_column
    id_column

    column :photos do |property|
      if property.photos.attached?
        image_tag(
          property.photos.first.variant(resize_to_limit: [80, 60]),
          width: 80,
          height: 60
        )
      else
        status_tag "No Photo"
      end
    end

    column :title

    column :user do |property|
      if property.user
        link_to property.user.email, admin_user_path(property.user)
      else
        "-"
      end
    end

    column :listing_type do |property|
      status_tag property.listing_type&.humanize
    end

    column :property_type do |property|
      property.property_type&.humanize
    end

    column :city
    column :locality
    column :price do |property|
      number_to_currency(property.price, unit: "₹", format: "%u%n")
    end

    column :bedrooms
    column :area_sqft

    column :available do |property|
      property.available? ? status_tag("Available", class: "ok") : status_tag("Unavailable", class: "warning")
    end

    column :created_at

    actions
  end

  # --------------------------------------------------
  # Show Page
  # --------------------------------------------------
  show do
    attributes_table do
      row :id
      row :title
      row :description

      row :user do |property|
        property.user&.email
      end

      row :listing_type do |property|
        property.listing_type&.humanize
      end

      row :property_type do |property|
        property.property_type&.humanize
      end

      row :furnishing do |property|
        property.furnishing_label
      end

      row :poster_type do |property|
        property.poster_type&.humanize
      end

      row :price do |property|
        number_to_currency(property.price, unit: "₹", format: "%u%n")
      end

      row :security_deposit do |property|
        if property.security_deposit.present?
          number_to_currency(property.security_deposit, unit: "₹", format: "%u%n")
        else
          "-"
        end
      end

      row :address
      row :locality
      row :city
      row :pincode
      row :contact_phone

      row :bedrooms
      row :bathrooms
      row :area_sqft
      row :parking_spaces
      row :floor_number
      row :total_floors

      row :available do |property|
        property.available? ? status_tag("Available", class: "ok") : status_tag("Unavailable", class: "warning")
      end

      row :available_from

      row :amenities do |property|
        if property.amenities.present?
          safe_join(
            property.amenities.map { |amenity| status_tag(amenity) },
            " "
          )
        else
          "-"
        end
      end

      row :latitude
      row :longitude

      row :maps do |property|
        link_to(
          "Open in Google Maps",
          "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(property.maps_query)}",
          target: "_blank",
          rel: "noopener"
        )
      end

      row :photos do |property|
        if property.photos.attached?
          div do
            property.photos.each do |photo|
              span do
                image_tag(
                  photo.variant(resize_to_limit: [180, 130]),
                  style: "margin: 5px; border-radius: 6px;"
                )
              end
            end
          end
        else
          "No photos uploaded"
        end
      end

      row :videos do |property|
        if property.videos.attached?
          div do
            property.videos.each do |video|
              video_tag(
                video,
                controls: true,
                width: 300,
                style: "margin: 5px;"
              )
            end
          end
        else
          "No videos uploaded"
        end
      end

      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  # --------------------------------------------------
  # Form
  # --------------------------------------------------
  form do |f|
    f.semantic_errors

    f.inputs "Basic Information" do
      f.input :user,
              collection: User.all.order(:email),
              include_blank: false

      f.input :title
      f.input :description

      f.input :listing_type,
              as: :select,
              collection: Property.listing_types.keys.map { |key| [key.humanize, key] }

      f.input :property_type,
              as: :select,
              collection: Property.property_types.keys.map { |key| [key.humanize, key] }

      f.input :furnishing,
              as: :select,
              collection: Property.furnishings.keys.map { |key| [key.humanize, key] }

      f.input :poster_type,
              as: :select,
              collection: Property.poster_types.keys.map { |key| [key.humanize, key] }
    end

    f.inputs "Pricing" do
      f.input :price

      f.input :security_deposit,
              hint: "Security deposit applies to rental properties."
    end

    f.inputs "Location" do
      f.input :address
      f.input :locality
      f.input :city
      f.input :pincode
      f.input :latitude
      f.input :longitude
    end

    f.inputs "Property Details" do
      f.input :bedrooms
      f.input :bathrooms
      f.input :area_sqft
      f.input :parking_spaces
      f.input :floor_number
      f.input :total_floors
    end

    f.inputs "Availability" do
      f.input :available

      f.input :available_from,
              as: :datepicker

    end

    f.inputs "Amenities" do
      f.input :amenities,
              as: :check_boxes,
              collection: Property::AMENITIES
    end

    f.inputs "Photos" do
      f.input :photos,
              as: :file,
              input_html: {
                multiple: true,
                accept: "image/*"
              }

      if f.object.photos.attached?
        ul class: "active_admin_images" do
          f.object.photos.each do |photo|
            li do
              image_tag(
                photo.variant(resize_to_limit: [150, 100]),
                style: "margin: 5px;"
              )
            end
          end
        end
      end
    end

    f.inputs "Videos" do
      f.input :videos,
              as: :file,
              input_html: {
                multiple: true,
                accept: "video/*"
              }
    end

    f.actions
  end

  # --------------------------------------------------
  # Scopes
  # --------------------------------------------------
  scope :all, default: true
  scope :available do |properties|
    properties.where(available: true)
  end

  scope :rent do |properties|
    properties.where(listing_type: Property.listing_types[:rent])
  end

  scope :buy do |properties|
    properties.where(listing_type: Property.listing_types[:buy])
  end

  # --------------------------------------------------
  # Custom Actions
  # --------------------------------------------------
  member_action :mark_available, method: :put do
    resource.update!(available: true)

    redirect_to(
      resource_path(resource),
      notice: "Property marked as available."
    )
  end

  member_action :mark_unavailable, method: :put do
    resource.update!(available: false)

    redirect_to(
      resource_path(resource),
      notice: "Property marked as unavailable."
    )
  end

  # --------------------------------------------------
  # Batch Actions
  # --------------------------------------------------
  batch_action :mark_available do |ids|
    Property.where(id: ids).update_all(available: true)

    redirect_to(
      collection_path,
      notice: "#{ids.size} properties marked as available."
    )
  end

  batch_action :mark_unavailable do |ids|
    Property.where(id: ids).update_all(available: false)

    redirect_to(
      collection_path,
      notice: "#{ids.size} properties marked as unavailable."
    )
  end

  # --------------------------------------------------
  # Member Action Links
  # --------------------------------------------------
  action_item :mark_available,
              only: :show,
              if: proc { !resource.available? } do
    link_to(
      "Mark Available",
      mark_available_admin_property_path(resource),
      method: :put
    )
  end

  action_item :mark_unavailable,
              only: :show,
              if: proc { resource.available? } do
    link_to(
      "Mark Unavailable",
      mark_unavailable_admin_property_path(resource),
      method: :put
    )
  end

  # --------------------------------------------------
  # Controller Customization
  # --------------------------------------------------
  controller do
    def scoped_collection
      super.includes(:user)
    end
  end
end

