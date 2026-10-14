# spec/factories/properties.rb
FactoryBot.define do
  factory :property do
    # Association linking back to the user factory
    association :user

    title { "Spacious 3 BHK Apartment" }
    address { "123 Green Glen Layout" }
    city { "Bangalore" }
    contact_phone { "+919876543210" }
    price { 2500000 }
    pincode { "560103" } # Enforces your 6-digit regex validation
    security_deposit { 50000 }
    latitude { 12.9716 }
    longitude { 77.5946 }
    
    listing_type { :buy }
    property_type { :apartment }
    furnishing { :semi_furnished }
    poster_type { :owner }
    available { true }
    status { "published" }
    amenities { ["Lift", "Power backup", "CCTV", "24x7 security"] }

    # Trait specifically tailored for Land Listings (handles the conditional validations)
    trait :land_listing do
      listing_type { :land }
      property_type { :plot }
      land_type { :residential }
      land_area { 1200.0 }
      area_unit { "sqft" }
      facing { "East" }
      road_width_ft { 30 }
      plot_length { 40.0 }
      plot_width { 30.0 }
    end

    # Specialized states
    trait :for_rent do
      listing_type { :rent }
      price { 25000 }
    end

    trait :draft do
      status { "draft" }
    end

    # Active Storage Attachment Mocking (Gallery requirement)
    trait :with_gallery do
      after(:build) do |property|
        property.gallery.attach(
          io: File.open(Rails.root.join('spec', 'support', 'assets', 'test_property.png')),
          filename: 'test_property.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
