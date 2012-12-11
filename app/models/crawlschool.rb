class Crawlschool < ActiveRecord::Base

  has_many :crawlprofs
  belongs_to :school

end
