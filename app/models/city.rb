class City < ActiveRecord::Base
  acts_as_mappable

  belongs_to :state
  has_and_belongs_to_many :questions
  has_many :schools
  has_many :replacements, :as => :replaceable
  belongs_to :area
  belongs_to :county
  has_many :placewages
  
  def self.all_prim
    City.find_all_by_prim(true)
  end

end
