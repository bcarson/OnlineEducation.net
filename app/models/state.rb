class State < ActiveRecord::Base
  acts_as_mappable

  has_many :cities
  has_many :schools
  has_many :replacements, :as => :replaceable
  has_and_belongs_to_many :questions
  has_many :counties
  has_many :areas
  
  def prim_cities
    City.find(:all, :conditions => ['prim = ? and state_id = ?', true, self.id], :order => 'population DESC')
  end
  
  def name
    self.full_name
  end
  
end
