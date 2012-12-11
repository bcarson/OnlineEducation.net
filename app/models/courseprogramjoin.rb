class Courseprogramjoin < ActiveRecord::Base

  belongs_to :course
  belongs_to :program 

end
