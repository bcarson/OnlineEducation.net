class Zarea < ActiveRecord::Base
  
  has_many :zareawages
  belongs_to :state
  has_many :cities 
  
  def safe_name
    return self.name.gsub(/, [A-Z][A-Z]/,'').gsub(/area$/,'').gsub("Division", '')
  end
  
end
