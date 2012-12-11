class Area < ActiveRecord::Base
  
  belongs_to :state
  has_many :cities
  has_many :placewages
  
  
end
