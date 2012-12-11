class Profession < ActiveRecord::Base

  has_and_belongs_to_many :subjects
  has_many :replacements, :as => :replaceable
  has_and_belongs_to_many :questions
  has_many :placewages
  has_and_belongs_to_many :zoccupations
  
  def an_name
    @a = self.name.first
    if @a == 'a' || @a == 'e' || @a == 'i' || @a == 'o' || @a == 'u' || @a == 'A' || @a == 'E' || @a == 'I' || @a == 'O' || @a == 'U'
      return 'an ' + self.name  
    else
      if self.name == 'Herbalist'
        return 'an ' + self.name 
      else
        return 'a ' + self.name    
      end
    end
  end  
  
  
  def opt_subjects
    @a = []
    if @p = Subject.find_by_id(self.prim_subject_id)
      @a << @p
    end
    for p in self.subjects
      @a << p if !@a.index(p)
    end
    return @a
  end
  
  
  def primarysubject
    Subject.find_by_id(self.prim_subject_id)
  end
  
  def primaryzocc
    Zoccupation.find_by_id(self.prim_zocc_id)
  end
  
  def opt_zoccs
    @a = []
    if @z = Zoccupation.find_by_id(self.prim_zocc_id)
      @a << @z
    end
    for z in self.zoccupations
      @a << z if !@a.index(z)
    end
    return @a        
  end
  
  def safe_plural_downcase_name
    
    case self.name
      when 'Camera Man'
        return 'camera men'
      when 'Salesman'
        return 'saleswomen'
      when /coach$/i
        return self.name.downcase + 'es'
      when 'ESL Trainer'
        return 'ESL trainers'
      when 'ESL Teacher'
        return 'ESL teachers'
      when 'ESL Tutor'
        return 'ESL tutors'
      when 'ESL Educator'
        return 'ESL educators'
      when 'PE Teacher'
        return 'PE teachers'
      when 'PE Trainer'
        return 'PT trainers'
      when 'M and A Lawyer'
        return 'M and A lawyers'
      when /IT [A-Z]/ || /UI [A-Z]/ || /UX [A-Z]/ || /HVAC [A-Z]/
        @p = self.name.split
        return @p.first + ' ' + @p.second.downcase + 's'
      when /man$/
        return self.name.downcase.gsub(/man$/, 'men')
      when /y$/
        return self.name.downcase.gsub(/y$/,'ies')
      when 'X-Ray Technician'
        return 'X-ray technicians'
      when ['SEO', 'CEO', 'CFO', 'CTO', 'CPA', 'EMT', 'LPN', 'RN', 'LVN', 'PT'].index(self.name)    
        return self.name + 's'
      when /[A-Z]\)$/i
        return self.name.downcase.gsub(/\s\(.+\)\s*/,'') + 's'     
      when /^[A-Z]+$/
        return self.name + 's'   
      else
        return self.name.downcase.gsub(/\s\(.+\)\s*/,'') + 's'
    end
  end

end
