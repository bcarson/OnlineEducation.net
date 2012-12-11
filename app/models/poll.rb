class Poll < ActiveRecord::Base
  
  has_many :pollvotes
  has_many :pollitems
  
end