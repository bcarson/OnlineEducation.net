class Sentence < ActiveRecord::Base

  belongs_to :answer
  belongs_to :pageheading
  has_many :spins

end