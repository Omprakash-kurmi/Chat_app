# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # Generates a unique email for every user instance
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { password }

    # Validates under your 50 and 280 character limits
    name { "Jane Doe" }
    bio { "Hello! I am a passionate home seeker looking for great properties." }

    # Defaults to the first enum value as per your configuration
    role { :customer }
    admin { false }

    # Traits to easily toggle user states/roles in tests
    trait :admin do
      admin { true }
    end

    trait :vendor do
      role { :vendor }
    end

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: File.open(Rails.root.join("spec", "support", "assets", "test_avatar.png")),
          filename: "test_avatar.png",
          content_type: "image/png"
        )
      end
    end

    # OmniAuth Mock Setup
    trait :google_authenticated do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-12345#{n}" }
      avatar_url { "https://googleusercontent.com" }
    end
  end
end
