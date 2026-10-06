namespace :demo do
  desc "Fill the new detail fields on existing listings"
  task backfill_property_details: :environment do
    pins = { "Indore" => 452001, "Bhopal" => 462001, "Pune" => 411001, "Mumbai" => 400001, "Bengaluru" => 560001,
             "Hyderabad" => 500001, "Jaipur" => 302001, "Ahmedabad" => 380001, "Sagar" => 470001 }
    count = 0

    Property.find_each do |home|
      flat = home.apartment? || home.penthouse? || home.studio?
      total = flat ? rand(4..25) : nil
      attrs = {
        locality: home.locality.presence || home.address.to_s.split(",").last.to_s.strip,
        pincode: home.pincode.presence || ((pins[home.city] || 100_001) + rand(0..40)).to_s,
        furnishing: home.plot? ? 0 : rand(0..2),
        parking_spaces: home.plot? ? 0 : (home.villa? || home.house? ? rand(1..3) : rand(0..2)),
        amenities: Property::AMENITIES.sample(home.plot? ? rand(0..3) : rand(3..9)),
        available_from: [ nil, nil, nil, Date.current + rand(1..45) ].sample,
        floor_number: flat ? rand(0..total) : nil,
        total_floors: total,
        age_years: home.plot? ? nil : rand(0..20),
        poster_type: rand(0..1),
        contact_name: home.user.try(:display_name),
        security_deposit: home.rent? ? (home.price * rand(2..6) / 1000.0).round * 1000 : nil
      }
      home.update_columns(attrs)
      count += 1
    end
    puts "Updated #{count} listings."
  end
end
