class Zoccupation < ActiveRecord::Base
  
  has_and_belongs_to_many :professions
  has_one :zoccupationstat, :foreign_key => 'occupation_id', :primary_key => 'occ_id'
  has_many :zareawages, :foreign_key => 'occupation_id', :primary_key => 'occ_id'
  has_many :zstatewages, :foreign_key => 'occ_id', :primary_key => 'occ_id', :conditions => ['year = ?', 2009]
    
  def safe_name
    return self.name.gsub(', all other','').gsub(/, except .+/i,'').gsub(/, postsecondary/,'').gsub('occupations', 'employees').gsub(/\s\(.+\)\s*/,'')
  end
      
end
