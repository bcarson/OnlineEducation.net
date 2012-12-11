class Zareawage < ActiveRecord::Base
  
  belongs_to :zoccupations, :foreign_key => 'occ_id', :primary_key => 'occupation_id'
  belongs_to :zarea, :primary_key => 'area_id'
  
end
