tag_class = { "pending" => "warning", "published" => "ok", "rejected" => "error", "closed" => "" }

ActiveAdmin.register Property do
  menu priority: 3, label: "Listings"
  actions :index, :show, :edit, :update, :destroy
  permit_params :status, :rejection_reason

  scope :all
  scope :pending, default: true
  scope :published
  scope :rejected
  scope :closed

  filter :title
  filter :city
  filter :listing_type, as: :select, collection: -> { Property.listing_types }
  filter :property_type, as: :select, collection: -> { Property.property_types }
  # filter :status, as: :select, collection: -> { Property.statuses }
  filter :created_at

  includes :user

  index do
    selectable_column
    id_column
    column :title
    column("Owner") { |p| p.user.try(:display_name).presence || p.user.try(:email) }
    column :listing_type
    column :property_type
    column :city
    column("Price") { |p| number_to_currency(p.price, unit: "₹", precision: 0) }
    column("Status") { |p| status_tag p.status_label, class: tag_class[p.status] }
    column :created_at
    actions defaults: true do |p|
      if p.pending? || p.rejected?
        item "Approve", approve_admin_property_path(p), method: :put, class: "member_link"
      end
    end
  end

  show do
    attributes_table do
      row :title
      row("Owner") { |p| "#{p.user.try(:display_name)} (#{p.user.try(:email)})" }
      row("Status") { |p| status_tag p.status_label, class: tag_class[p.status] }
      row :rejection_reason
      row :listing_type
      row :property_type
      row("Price") { |p| number_to_currency(p.price, unit: "₹", precision: 0) }
      row :security_deposit
      row("Address") { |p| [ p.address, p.locality, p.city, p.pincode ].compact_blank.join(", ") }
      row :bedrooms
      row :bathrooms
      row :area_sqft
      row :furnishing
      row("Amenities") { |p| p.amenities.join(", ") }
      row :contact_name
      row :contact_phone
      row :description
      row("Photos") do |p|
        safe_join(p.photos.map { |ph| link_to(image_tag(ph.variant(resize_to_fill: [ 160, 120 ]), style: "margin:4px"), url_for(ph), target: "_blank") })
      end
      row("Videos") { |p| p.videos.attached? ? safe_join(p.videos.map { |v| link_to(v.filename.to_s, url_for(v), target: "_blank") }, ", ") : "—" }
    end
  end

  form do |f|
    f.inputs "Moderation" do
      f.input :status, as: :select, collection: Property.statuses.keys, include_blank: false
      f.input :rejection_reason, hint: "Shown to the owner when a listing is rejected."
    end
    f.actions
  end

  # --- one-click approve ----------------------------------------------------
  member_action :approve, method: :put do
    if resource.approve!
      redirect_to resource_path, notice: "Listing approved and published."
    else
      redirect_to resource_path, alert: "This listing can't be approved from its current status."
    end
  end

  action_item :approve, only: :show, if: proc { resource.pending? || resource.rejected? } do
    link_to "Approve & publish", approve_admin_property_path(resource), method: :put
  end

  # --- bulk actions ---------------------------------------------------------
  batch_action :approve, confirm: "Publish the selected listings?" do |ids|
    done = batch_action_collection.find(ids).count(&:approve!)
    redirect_to collection_path, notice: "#{done} listing(s) published."
  end

  batch_action :reject, form: { reason: :text } do |ids, inputs|
    done = batch_action_collection.find(ids).count { |p| p.reject!(inputs["reason"]) }
    redirect_to collection_path, notice: "#{done} listing(s) rejected. Owners can see the reason and resubmit."
  end
end
