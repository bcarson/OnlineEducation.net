class Program < ActiveRecord::Base
  
  #has_many :degrees
  has_and_belongs_to_many :subjects
  belongs_to :school
  has_and_belongs_to_many :degreelevels
  has_and_belongs_to_many :concentrations
  has_many :courseprogramjoins
  has_many :courses, :through => :courseprogramjoins
  
  def degree
    self.degrees.first  
  end
  
  def getinfourl(url_string='',loc='')
    url_string = '-' if url_string.blank?
    '/getinfo/' + Worker.inurl(self.name) + '/program/' + self.id.to_s + '/' + url_string + '/' + loc
  end
      
  def self.top_online_certifications(subject)    
    if subject.blank?
      Program.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['programs.is_online = 1 AND programs.inactive IS NULL AND degreelevels.id = ?', 69], :include => [:degreelevels, :school])
    else
      Program.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['programs.is_online = 1 AND programs.inactive IS NULL AND subjects.id = ? AND degreelevels.id = ?', subject.id, 69], :include => [:degreelevels, :school, :subjects])
    end
  end
  
  def self.top_online_programs(subject)    
    if subject.blank?
      Program.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['programs.is_online = 1 AND programs.inactive IS NULL'], :include => [:school])
    else
      Program.find(:all, :limit => 70, :order => ['schools.priority DESC'], :conditions => ['programs.is_online = 1 AND programs.inactive IS NULL AND subjects.id = ?', subject.id, 69], :include => [:school, :subjects])
    end
  end
  
  
  def zcourselist
    @output = '' 
    for course in self.courses 
  	  @output += course.name if !course.name.blank? 
  	  @output += '|'
  	  @output += course.number if !course.number.blank? 
    	@output += '|'
      @c = Courseprogramjoin.find_by_course_id_and_program_id(course.id, self.id)
  	  @output += @c.is_optional ? 'y' : ''
    	@output += '|'
  	  @output += course.id.to_s 	
  	  @output += "\n"
  	end
    @output 
  end
      
end
