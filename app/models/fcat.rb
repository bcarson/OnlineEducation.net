class Fcat < ActiveRecord::Base

  has_many :fsubs
  belongs_to :fdeg

end
