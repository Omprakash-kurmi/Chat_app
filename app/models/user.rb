class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def admin?
    admin == true
  end
  
  def self.ransackable_attributes(auth_object = nil)
    ["email", "created_at", "updated_at", "id", "admin"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["messages"]
  end       
end
