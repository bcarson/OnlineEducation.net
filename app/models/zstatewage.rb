class Zstatewage < ActiveRecord::Base
  
  belongs_to :zoccupations, :foreign_key => 'occ_id', :primary_key => 'occ_id'
  belongs_to :state
  
end
