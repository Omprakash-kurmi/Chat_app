class Room < ApplicationRecord
	has_many :messages, dependent: :destroy
	
  def self.ransackable_attributes(auth_object = nil)
    ["name", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["messages"]
  end
end
