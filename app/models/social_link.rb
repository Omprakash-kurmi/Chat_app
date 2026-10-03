class SocialLink < ApplicationRecord
  default_scope { order(:position) }
  validates :platform, :url, presence: true
end
