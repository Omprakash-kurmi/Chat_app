module InquiriesHelper
  def inr(amount)
    number_to_currency(amount, unit: "₹", precision: 0, delimiter_pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/)
  end

  def status_pill(status, label)
    content_tag(:span, label, class: "st st-#{status}")
  end

  def inquiry_status_pill(inquiry)
    status_pill(inquiry.status, inquiry.status_label)
  end

  def property_status_pill(property)
    status_pill(property.status, property.status_label)
  end

  # number shown on the navbar badge: new inquiries waiting for the owner's reply
  def pending_inquiries_count
    return 0 unless user_signed_in?
    @pending_inquiries_count ||= Inquiry.pending.where(property_id: current_user.properties.select(:id)).count
  end
end
