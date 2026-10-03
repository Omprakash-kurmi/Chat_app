class FooterColumn < ApplicationRecord
  has_many :footer_links, -> { order(:position) }, dependent: :destroy
  default_scope { order(:position) }
  validates :title, presence: true
end
