class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  validates :name, length: { maximum: 50 }
  validates :bio, length: { maximum: 280 }
  after_create_commit :send_welcome_email

  def admin?
    admin == true
  end

  def display_name
    name.presence || email.split("@").first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "email", "name", "created_at", "updated_at", "id", "admin" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "messages" ]
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
