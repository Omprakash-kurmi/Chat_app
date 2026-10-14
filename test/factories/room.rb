FactoryBot.define do
  factory :room do
    sequence(:name) { |n| "Test Room #{n}" }
  end
end
