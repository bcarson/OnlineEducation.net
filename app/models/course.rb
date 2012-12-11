class Course < ActiveRecord::Base
  
  belongs_to :school
  has_and_belongs_to_many :subjects
  has_many :paragraphs, :as => :paragraphable
  has_many :courseprogramjoins
  has_many :programs, :through => :courseprogramjoins
    
  def self.top_online_courses(subject)    
    if subject.blank?
      Course.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['schools.is_online = 1'], :include => [:school])
    else
      Course.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['schools.is_online = 1 AND subjects.id = ?', subject.id], :include => [:subjects, :school])
    end
  end    
end
