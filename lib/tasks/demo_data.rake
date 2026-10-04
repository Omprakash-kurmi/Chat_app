require "zlib"
require "stringio"

module DemoData
  DOMAIN = "demo.example".freeze

  CITIES = {
    "Indore"    => [ "Vijay Nagar", "Palasia", "Saket Nagar", "Bhawarkua", "Rau", "Nipania" ],
    "Bhopal"    => [ "Arera Colony", "MP Nagar", "Kolar Road", "Bawadiya Kalan" ],
    "Pune"      => [ "Baner", "Kothrud", "Wakad", "Hinjewadi", "Viman Nagar" ],
    "Mumbai"    => [ "Andheri West", "Powai", "Thane West", "Navi Mumbai" ],
    "Bengaluru" => [ "Whitefield", "Indiranagar", "HSR Layout", "Electronic City" ],
    "Hyderabad" => [ "Gachibowli", "Madhapur", "Kondapur", "Banjara Hills" ],
    "Jaipur"    => [ "Vaishali Nagar", "Malviya Nagar", "Mansarovar" ],
    "Ahmedabad" => [ "Satellite", "Bopal", "Prahlad Nagar" ]
  }.freeze

  VENDOR_NAMES = [ "Sharma Realty", "Patel Estates", "Verma Homes", "Iyer Properties", "Khan & Sons Realtors" ].freeze
  ADJECTIVES   = %w[Spacious Sunny Well-kept Modern Cozy Elegant Airy Premium].freeze
  LANDMARKS    = [ "City Mall", "Central Park", "the metro station", "the main market", "District Hospital", "a public school" ].freeze
  VISITING     = [ "Mon–Sat, 10am–6pm", "Daily, 9am–7pm", "Mon–Fri, 10am–4pm", "Sat–Sun, 11am–5pm", "By appointment, any day" ].freeze
  FEATURES = [
    "Close to schools, markets and public transport.", "24x7 water supply and power backup.",
    "Gated society with round-the-clock security.", "Plenty of natural light and cross ventilation.",
    "Covered parking for two vehicles.", "Quiet, tree-lined neighbourhood.",
    "Modular kitchen with ample storage.", "Spacious balcony with a pleasant view.",
    "Clubhouse, garden and children's play area.", "Recently painted and move-in ready."
  ].freeze
  PALETTES = [
    [ [ 91, 33, 240 ], [ 232, 84, 62 ] ], [ [ 15, 157, 110 ], [ 20, 22, 40 ] ], [ [ 255, 138, 92 ], [ 124, 77, 255 ] ],
    [ [ 52, 98, 249 ], [ 29, 154, 108 ] ], [ [ 194, 120, 3 ], [ 91, 33, 240 ] ], [ [ 232, 84, 62 ], [ 27, 31, 59 ] ],
    [ [ 29, 154, 108 ], [ 255, 214, 120 ] ], [ [ 124, 77, 255 ], [ 20, 160, 200 ] ]
  ].freeze

  @phone_seq = 0

  # Builds a gradient PNG with no extra gems.
  def self.png(from, to, w = 800, h = 520)
    raw = String.new
    h.times do |y|
      t = y.to_f / (h - 1)
      r, g, b = from.zip(to).map { |a, z| (a + (z - a) * t).round }
      raw << "\x00".b << ([ r, g, b ].pack("C3") * w)
    end
    chunk = ->(type, data) { [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N") }
    "\x89PNG\r\n\x1a\n".b +
      chunk.("IHDR", [ w, h, 8, 2, 0, 0, 0 ].pack("NNCCCCC")) +
      chunk.("IDAT", Zlib.deflate(raw)) +
      chunk.("IEND", "")
  end

  def self.generated_images
    @generated_images ||= PALETTES.each_with_index.map { |(from, to), i| [ png(from, to), "placeholder-#{i + 1}.png" ] }
  end

  # Real photos dropped into db/seed_images/ are used instead of placeholders.
  def self.real_images
    @real_images ||= Dir[Rails.root.join("db/seed_images/*.{jpg,jpeg,png,webp}")].select { |p| File.size(p) <= 5.megabytes }.map do |path|
      type = { ".jpg" => "image/jpeg", ".jpeg" => "image/jpeg", ".png" => "image/png", ".webp" => "image/webp" }[File.extname(path).downcase]
      [ File.binread(path), File.basename(path), type ]
    end
  end

  def self.photos
    pool = real_images.presence || generated_images.map { |bytes, name| [ bytes, name, "image/png" ] }
    pool.sample(rand(3..5)).map { |bytes, name, type| { io: StringIO.new(bytes), filename: name, content_type: type } }
  end

  def self.vendors
    VENDOR_NAMES.each_with_index.map do |name, i|
      User.find_or_create_by!(email: "vendor#{i + 1}@#{DOMAIN}") do |u|
        u.password = "password123"
        u.role = :vendor
        u.display_name = name if u.respond_to?(:display_name=)
        u.skip_confirmation! if u.respond_to?(:skip_confirmation!)
      end
    end
  end

  def self.create_listing(vendor, listing_type)
    rent = listing_type == "rent"
    type = (rent ? %w[apartment apartment apartment house house villa] : %w[apartment apartment house house villa plot]).sample
    city = (CITIES.keys + [ "Indore" ] * 3).sample
    locality = CITIES[city].sample

    if type == "plot"
      beds = baths = nil
      area = rand(600..4000)
    else
      beds = { "apartment" => [ 1, 2, 2, 3, 3, 4 ], "house" => [ 2, 3, 3, 4 ], "villa" => [ 3, 4, 4, 5 ] }[type].sample
      baths = [ beds - rand(0..1), 1 ].max
      area = beds * rand({ "apartment" => 350..550, "house" => 450..700, "villa" => 700..1000 }[type])
    end

    price = if rent
      [ (area * rand(14..40) / 500.0).round * 500, 5000 ].max
    else
      rate = type == "plot" ? rand(1500..6000) : rand(3500..11000)
      (area * rate / 50_000.0).round * 50_000
    end

    title = if type == "plot"
      "#{area} sq ft residential plot in #{locality}"
    else
      "#{ADJECTIVES.sample} #{beds}BHK #{type} in #{locality}"
    end
    unit = type == "apartment" ? "Flat #{rand(101..1204)}" : "House no. #{rand(1..250)}"
    kind = type == "plot" ? "plot of land" : type
    description = "#{ADJECTIVES.sample} #{kind} of #{area} sq ft in #{locality}, #{city}, " \
                  "#{rent ? 'available for rent' : 'for sale'}. #{FEATURES.sample(3).join(' ')}"

    @phone_seq += 1
    vendor.properties.create!(
      title: title, listing_type: listing_type, property_type: type, price: price,
      bedrooms: beds, bathrooms: baths, area_sqft: area,
      address: "#{unit}, near #{LANDMARKS.sample}, #{locality}", city: city,
      description: description, contact_phone: format("90000 %05d", @phone_seq),
      visiting_hours: VISITING.sample, available: rand < 0.9,
      photos: photos, created_at: rand(60).days.ago - rand(24).hours
    )
  end
end

namespace :demo do
  desc "Create demo vendors plus rent and sale listings. Usage: bin/rails 'demo:properties[40]'"
  task :properties, [ :per_type ] => :environment do |_, args|
    per_type = (args[:per_type] || 40).to_i
    vendors = DemoData.vendors
    %w[rent buy].each do |type|
      per_type.times { |i| DemoData.create_listing(vendors[i % vendors.size], type) }
      puts "Created #{per_type} #{type == 'rent' ? 'rent' : 'sale'} listings"
    end
    puts "Done. Log in as vendor1@#{DemoData::DOMAIN} / password123 to manage the listings."
  end

  desc "Remove all demo vendors and their listings"
  task clear_properties: :environment do
    users = User.where("email LIKE ?", "%@#{DemoData::DOMAIN}")
    listings = Property.where(user: users).count
    vendors = users.count
    users.destroy_all
    puts "Removed #{listings} listings and #{vendors} demo vendors."
  end
end
