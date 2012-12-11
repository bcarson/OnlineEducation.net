class Subject < ActiveRecord::Base
     
  has_and_belongs_to_many :courses
  has_and_belongs_to_many :professions
  has_and_belongs_to_many :images
  has_and_belongs_to_many :questions
  has_and_belongs_to_many :schools
  has_and_belongs_to_many :programs
  has_and_belongs_to_many :degreelevels
  has_and_belongs_to_many :questions
  has_and_belongs_to_many :featuredprograms, :order => 'featuredschools.votes DESC', :include => [:featuredschool]
  has_many :replacements, :as => :replaceable
  has_many :featuredschoolsubjects
  has_many :featuredschools, :through => :featuredschoolsubjects, :order => 'votes DESC'
      
  def parent
    if self.parent_id.blank?
      return self
    else
      return Subject.find(self.parent_id)
    end
  end
  
  def opt_professions
    
    @a = []
    if @p = Profession.find_by_id(self.prim_profession_id)
      @a << @p
    end
    for p in self.professions
      @a << p if !@a.index(p)
    end
    return @a
  end

  
  def small_icon_url
    return '/images/subjecticon-' + Worker.inurl(self.categorysubject.name) + '-small.png'      
  end
  
  def large_icon_url
    return '/images/subjecticon-' + Worker.inurl(self.categorysubject.name) + '.png'      
  end
  
  def questions_link(thecolor=nil)
    @output = '<a '
    @output += 'style="color:' + thecolor + '" ' if !thecolor.blank? 
    @output += 'href="/' + Worker.inurl(self.name) + '-questions">' + self.name + ' Questions</a>'
    return @output 
    
  end
  
  
  def categorysubject
    @subject = self
    while !@subject.parent_id.blank?
      @subject = @subject.parent  
    end
    return @subject
  end
  
  def siblings
    Subject.find_all_by_parent_id(self.parent_id)
  end
  
  def prim_siblings
    Subject.find(:all, :conditions => ['parent_id = ? and prim = ?', self.parent_id, true], :order => 'name')
  end  
  
  def prim_siblings_or_kids
    if self.parent_id.blank? 
      self.prim_kids
    else
      self.prim_siblings 
    end      
  end  
  
  def prim_siblings_or_kids_for_programs
    
  end
  
  def kids
    Subject.find(:all, :conditions => ['parent_id = ?', self.id], :order => 'name')
  end
  
  def prim_kids
    Subject.find(:all, :conditions => ['parent_id = ? and prim = ?', self.id, true], :order => 'name')
  end
  
  def self.all_prims_alpha_order
    self.find(:all, :conditions => ['prim = ?', true], :order => 'name')
  end
  
  def self.all_prims_vote_order
    self.find(:all, :conditions => ['prim = ?', true], :order => 'votes DESC')
  end  
  
  def self.all_secs_vote_order
    self.find(:all, :conditions => ['prim = ?', false], :order => 'votes DESC')
  end    
  
  def all_prim_kids
    @thereturn = []
    for sub in self.prim_kids
      @thereturn << sub
      for subj in sub.prim_kids
        @thereturn << subj  
      end  
    end
    if !@thereturn.blank? 
      return @thereturn.sort! {|a,b| a.name <=> b.name} 
    else
      return nil 
    end
  end
  
  def self.all_tls
    find(:all, :conditions => ['parent_id IS NULL'])
  end
  
  def is_tls?
    self.parent_id.blank? ? true : false 
  end
  
  def all_kids_alpha_order
    @thereturn = []
    for sub in self.kids
      @thereturn << sub
      for subj in sub.kids
        @thereturn << subj  
      end  
    end
    if !@thereturn.blank? 
      return @thereturn.sort! {|a,b| a.name <=> b.name} 
    else
      return nil 
    end
  end
  
  
  def self.nodes
    Subject.find(:all, :conditions => ['parent_id IS NULL'], :order => 'name')  
  end
  
  def an_name
    @a = self.name.first
    if @a == 'a' || @a == 'e' || @a == 'i' || @a == 'o' || @a == 'u' || @a == 'A' || @a == 'I' || @a == 'E' || @a == 'O' || @a == 'U'
      return 'an ' + self.name  
    else
      if self.name == 'Herbalist'
        return 'an ' + self.name 
      else
        return 'a ' + self.name    
      end
    end
  end
  
  
  def tls_icon_url
    
      @subject = self.categorysubject
      return '/images/subjecticon-' + Worker.inurl(@subject.name) + '-small.png'

  end  
  
  def primaryprofession
    Profession.find_by_id(self.prim_profession_id)
  end
  
  def filed_under
 
      @sub = self
      @cat = self.categorysubject
      if @cat != self
        return '<a href="/' + Worker.inurl(@cat.name) + '-questions">' + @cat.name + '</a> > <a href="/' + Worker.inurl(@sub.name) + '-questions">' + @sub.name + '</a>' 
      else
        return '<a href="/' + Worker.inurl(@cat.name) + '-questions">' + @cat.name + '</a>'
      end    
      
  end  
  
  def safe_downcase_name
    if ['BSN','CAD','CPA','EMS','EMT','ESL','HVAC','IT','LPN','LPN to BSN','LVN','MBA','MCSE','MSN','RN', 'RN to BSN'].index(self.name)
      return self.name
    else
      if self.name == 'PC Repair'
        return 'PC repair'
      else
        return self.name.downcase
      end
    end
  end
  
end
