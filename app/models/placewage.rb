class Placewage < ActiveRecord::Base
  
  belongs_to :profession
  belongs_to :city
  belongs_to :area
  
end
