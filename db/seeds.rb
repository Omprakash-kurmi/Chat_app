# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?

about = FooterColumn.create!(title: "About", position: 1)
[ [ "Contact us", "/contact" ], [ "About us", "/about" ], [ "Careers", "/careers" ] ].each_with_index do |(l, u), i|
  about.footer_links.create!(label: l, url: u, position: i)
end

help = FooterColumn.create!(title: "Help", position: 2)
[ [ "Payments", "/payments" ], [ "Shipping", "/shipping" ], [ "FAQ", "/faq" ] ].each_with_index do |(l, u), i|
  help.footer_links.create!(label: l, url: u, position: i)
end

policy = FooterColumn.create!(title: "Policy", position: 3)
[ [ "Terms of use", "/terms" ], [ "Privacy", "/privacy" ], [ "Security", "/security" ] ].each_with_index do |(l, u), i|
  policy.footer_links.create!(label: l, url: u, position: i)
end

quick = FooterColumn.create!(title: "Quick links", position: 99)
[ [ "Help center", "/help" ], [ "Advertise", "/advertise" ] ].each_with_index do |(l, u), i|
  quick.footer_links.create!(label: l, url: u, position: i)
end

[ [ "Facebook", "https://facebook.com" ], [ "X", "https://x.com" ], [ "YouTube", "https://youtube.com" ], [ "Instagram", "https://instagram.com" ] ]
  .each_with_index { |(p, u), i| SocialLink.create!(platform: p, url: u, position: i) }

{
  "company_name"   => "My Chat App",
  "mail_address"   => "My Chat App Pvt Ltd\nYour street address\nCity, State, 000000",
  "office_address" => "My Chat App Pvt Ltd\nYour street address\nCity, State, 000000",
  "telephone"      => "+91 00000 00000"
}.each { |k, v| SiteSetting.find_or_create_by!(key: k) { |s| s.value = v } }

pages = {
  "contact"   => [ "Contact us",      "Email us at support@example.com or write to the address in the footer. We reply within 2 working days." ],
  "about"     => [ "About us",        "My Chat App lets you talk to your friends and groups in live rooms, with voice, video and image sharing." ],
  "careers"   => [ "Careers",         "We're not hiring right now, but check back soon." ],
  "payments"  => [ "Payments",        "Information about accepted payment methods and billing will appear here." ],
  "shipping"  => [ "Shipping",        "Shipping information will appear here." ],
  "faq"       => [ "FAQ",             "Q: How do I join a room?\n\nA: Open Rooms and choose a room.\n\nQ: How do I send an image?\n\nA: Use the paperclip icon next to the message box." ],
  "terms"     => [ "Terms of use",    "Replace this with your terms of use." ],
  "privacy"   => [ "Privacy",         "Replace this with your privacy policy." ],
  "security"  => [ "Security",        "Replace this with a description of how you protect user data." ],
  "help"      => [ "Help center",     "Need help? Start with the FAQ or contact us." ],
  "advertise" => [ "Advertise",       "To advertise with us, contact us using the details in the footer." ]
}

pages.each do |slug, (title, body)|
  Page.find_or_create_by!(slug: slug) { |p| p.title = title; p.body = body }
  FooterLink.where(url: "/#{slug}").update_all(url: "/pages/#{slug}")
end
