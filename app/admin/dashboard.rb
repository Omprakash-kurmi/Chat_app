# frozen_string_literal: true

# ActiveAdmin.register_page "Dashboard" do
#   menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

#   content title: proc { I18n.t("active_admin.dashboard") } do
#     div class: "blank_slate_container", id: "dashboard_default_message" do
#       span class: "blank_slate" do
#         span I18n.t("active_admin.dashboard_welcome.welcome")
#         small I18n.t("active_admin.dashboard_welcome.call_to_action")
#       end
#     end
#   end # content
# end
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    props = Property.all
    week  = (6.days.ago.to_date..Date.current).map do |day|
      { label: day.strftime("%a"), count: props.where(created_at: day.all_day).count }
    end

    data = {
      users:        User.count,
      vendors:      props.distinct.count(:user_id),
      listings:     props.count,
      published:    props.where(status: "published").count,
      pending:      props.where(status: "pending").count,
      rejected:     props.where(status: "rejected").count,
      closed:       props.where(status: "closed").count,
      inquiries:    Inquiry.count,
      reviews:      Review.count,
      avg_rating:   Review.average(:rating)&.round(1),
      by_type:      props.group(:listing_type).count.transform_keys(&:to_s),
      week:         week,
      pending_list: props.where(status: "pending").order(created_at: :desc).limit(5).to_a,
      new_users:    User.order(created_at: :desc).limit(5).to_a
    }

    render partial: "admin/dashboard/overview", locals: { d: data }
  end
end
