class Concentration < ActiveRecord::Base
  
  has_and_belongs_to_many :programs
  
end
