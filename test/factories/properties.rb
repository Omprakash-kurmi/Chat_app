FactoryBot.define do
  factory :property do
    user { nil }
    title { "MyString" }
    listing_type { 1 }
    property_type { 1 }
    price { "9.99" }
    bedrooms { 1 }
    bathrooms { 1 }
    area_sqft { 1 }
    address { "MyString" }
    city { "MyString" }
    description { "MyText" }
    contact_phone { "MyString" }
    visiting_hours { "MyString" }
    available { false }
  end
end
