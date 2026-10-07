namespace :demo do
  desc "Give customer1@demo.example some favorites, saved searches and a notification"
  task favorites: :environment do
    user = User.find_by(email: "customer1@demo.example") || User.first
    abort "No user found. Run `bin/rails demo:inquiries` first or sign up a user." unless user

    homes = Property.listed.where.not(user_id: user.id).limit(4)
    homes.each { |p| user.favorites.find_or_create_by!(property: p) }

    sample = homes.first
    if sample
      filters = { "q" => sample.city.to_s, "max_price" => (sample.price.to_i * 1.2).round.to_s, "bedrooms" => sample.bedrooms.to_s }.reject { |_, v| v.blank? }
      name = SavedSearch.default_name(sample.listing_type, filters)
      user.saved_searches.find_or_create_by!(listing_type: sample.listing_type, name: name) { |s| s.filters = filters }
      user.notifications.find_or_create_by!(dedupe_key: "demo:welcome") do |n|
        n.kind = "saved_search_match"; n.title = "New match for “#{name}”"
        n.body = "#{sample.title} — #{[ sample.locality, sample.city ].compact_blank.join(', ')}"
        n.path = Rails.application.routes.url_helpers.property_path(sample)
      end
    end
    puts "#{user.email}: #{user.favorites.count} favorites, #{user.saved_searches.count} saved searches"
  end
end
