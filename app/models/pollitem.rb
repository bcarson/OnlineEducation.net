class Pollitem < ActiveRecord::Base
  
  has_many :pollvotes
  belongs_to :poll
  
end