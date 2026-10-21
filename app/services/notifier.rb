class Notifier
  def self.call(user:, title:, body: nil, path: nil)
    return if user.blank?
    Notification.create!(user: user, title: title, body: body, path: path)
  rescue StandardError => e
    Rails.logger.warn("[Notifier] #{e.class}: #{e.message}")
    nil
  end

  def self.name_of(u)
    u.try(:username).presence || u.try(:name).presence || u.email.to_s.split("@").first
  end

  # Customer sends an inquiry -> vendor is notified
  def self.inquiry_received(inquiry, customer:, vendor:)
    call(user: vendor,
         title: "New inquiry from #{name_of(customer)}",
         body: "For #{inquiry.property.try(:title)}. Open it to accept or reject.",
         path: Rails.application.routes.url_helpers.inquiry_path(inquiry))
  end

  # Vendor accepts or rejects -> customer is notified
  def self.inquiry_decided(inquiry, customer:, vendor:, accepted:)
    call(user: customer,
         title: accepted ? "Your inquiry was accepted ✅" : "Your inquiry was rejected",
         body: "#{name_of(vendor)} #{accepted ? 'accepted' : 'rejected'} your inquiry for #{inquiry.property.try(:title)}.",
         path: Rails.application.routes.url_helpers.inquiry_path(inquiry))
  end

  # Call not answered -> the person who was called is notified
  def self.missed_call(caller:, callee:, inquiry: nil)
    call(user: callee,
         title: "Missed call from #{name_of(caller)} 📞",
         body: "They tried to reach you but you were unavailable.",
         path: (Rails.application.routes.url_helpers.inquiry_path(inquiry) if inquiry))
  end

  # Deal completed -> customer is notified
  def self.deal_done(inquiry, customer:, vendor:)
    call(user: customer,
         title: "Deal done successfully 🎉",
         body: "Your deal for #{inquiry.property.try(:title)} with #{name_of(vendor)} is complete.",
         path: Rails.application.routes.url_helpers.inquiry_path(inquiry))
  end
end
