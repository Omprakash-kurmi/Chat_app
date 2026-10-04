class Page < ApplicationRecord
  validates :slug, :title, presence: true
  validates :slug, uniqueness: true

  def to_param = slug
end
