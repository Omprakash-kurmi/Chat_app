FactoryBot.define do
  factory :event do
    # Implicitly creates associated records using their respective factories
    association :user
    association :room

    title { "Community Meetup & Networking" }
    description { "An interactive gathering to discuss project developments and share ideas." }
    starts_at { 2.days.from_now } # Defaults to an upcoming event

    # Trait for upcoming events explicitly
    trait :upcoming do
      starts_at { 1.day.from_now }
    end

    # Trait for past events to test the .past scope
    trait :past do
      starts_at { 2.days.ago }
    end

    # Trait to automatically build a few RSVPs along with the event
    trait :with_rsvps do
      transient do
        rsvps_count { 3 }
      end

      after(:create) do |event, evaluator|
        create_list(:rsvp, evaluator.rsvps_count, event: event, status: "going")
      end
    end
  end
end
