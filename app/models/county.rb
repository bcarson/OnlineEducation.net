class County < ActiveRecord::Base

  has_many :cities
  belongs_to :state

end
