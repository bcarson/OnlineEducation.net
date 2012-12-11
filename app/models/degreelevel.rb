class Degreelevel < ActiveRecord::Base

  has_and_belongs_to_many :subjects
  has_and_belongs_to_many :featuredprograms  
  has_and_belongs_to_many :programs  
  has_and_belongs_to_many :questions
  
end
