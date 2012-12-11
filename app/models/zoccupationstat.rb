class Zoccupationstat < ActiveRecord::Base
  
  belongs_to :zoccupations, :foreign_key => 'occ_id', :primary_key => 'occupation_id'
    
end
