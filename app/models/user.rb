class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  has_one_attached :avatar
  has_many :properties, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  has_many :inquiry_messages, dependent: :destroy
  has_many :proposed_visits, class_name: "Visit", foreign_key: :proposed_by_id, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :saved_searches, dependent: :destroy

  enum :role, { customer: 0, vendor: 1 }, validate: true

  validates :name, length: { maximum: 50 }
  validates :bio, length: { maximum: 280 }
  after_create_commit :send_welcome_email

  def admin?
    admin == true
  end

  def display_name
    [ name, try(:username), email.to_s.split("@").first ].compact_blank.first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "email", "name", "created_at", "updated_at", "id", "admin", "role", "provider" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "messages" ]
  end

  def self.from_omniauth(auth)
    email    = auth.info.email.to_s.downcase
    verified = auth.extra&.raw_info&.email_verified != false

    # 1. already linked to this Google account
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    return new.tap { |u| u.errors.add(:email, "is not verified by Google") } unless email.present? && verified

    # 2. same email already registered the normal way: link it
    if (user = find_by(email: email))
      user.update(provider: auth.provider, uid: auth.uid, avatar_url: auth.info.image)
      return user
    end

    # 3. brand-new user
    user = new(email: email, password: Devise.friendly_token[0, 24],
               provider: auth.provider, uid: auth.uid, avatar_url: auth.info.image,
               name: auth.info.name.to_s.truncate(50, omission: ""))

    if user.has_attribute?(:username)
      base  = email.split("@").first.to_s.parameterize(separator: "_").presence || "user"
      uname = base
      uname = "#{base}_#{SecureRandom.hex(2)}" while exists?(username: uname)
      user.username = uname
    end

    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.role = :customer if user.role.blank?
    user.save
    user
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
