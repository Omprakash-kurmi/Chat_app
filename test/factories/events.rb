FactoryBot.define do
  factory :event do
    room { nil }
    user { nil }
    title { "MyString" }
    description { "MyText" }
    starts_at { "2026-10-03 11:21:49" }
  end
end
