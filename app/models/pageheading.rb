class Pageheading < ActiveRecord::Base

  belongs_to :page
  has_many :sentences

end