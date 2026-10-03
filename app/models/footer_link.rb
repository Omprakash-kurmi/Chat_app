class FooterLink < ApplicationRecord
  belongs_to :footer_column
  validates :label, :url, presence: true
end
