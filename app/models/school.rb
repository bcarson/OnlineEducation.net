class School < ActiveRecord::Base
  acts_as_mappable

  belongs_to :city
  belongs_to :state
  has_many :paragraphs, :as => :paragraphable
  has_many :degrees
  has_many :courses
  has_many :images
  has_and_belongs_to_many :subjects
  has_many :programs
  has_many :insiderguides
  has_many :comments
  has_many :ratings
  has_many :crawlschools
  
  def name_for_search
    self.name.gsub(/-.*$/,'')  
  end
  
  def url
    if !self.website.blank? 
      return self.website
    else
      return self.website_url
    end
  end
  
  def ytchannel
    if !self.you_tube_url.blank?
      @s = self.you_tube_url.scan(/\.com\/(.+?)(\/|\?|$)/)[0][0]
    end
    return @s
  end
  
  def matching_programs(subject=nil)
    self.programs.find(:all, :conditions => ['subjects.id = ?', subject.id], :include => [:subjects])  
  end
    
  def display_rank
    sprintf("%.2f", self.rank) 
  end

  def display_rank_online
    sprintf("%.0f", (self.priority / 100.00) * 100.00) 
  end
    
  def active_online_programs
    self.programs.find(:all, :conditions => ['is_online = 1 AND inactive IS NULL'])
    
    #Program.find(:)
    
  end
  
  def top_widget_programs
    #Program.find(:all, :limit => 3, :order => 'subjects.priority DESC', :conditions => ['is_online = 1 AND inactive IS NULL AND school_id = ?', self.id], :include => [:subjects])  
    Program.find(:all, :limit => 3, :conditions => ['is_online = 1 AND inactive IS NULL AND school_id = ?', self.id])  
    
  end
  
  def getinfourl(url_string='',loc='')
    url_string = '-' if url_string.blank? 
    '/getinfo/' + Worker.inurl(self.name) + '/school/' + self.id.to_s + '/' + url_string + '/' + loc
  end
    
  def self.all_online
    find(:all, :order => 'priority DESC', :conditions => ['is_online = 1'])
  end
    
  def is_online?
     !self.monetize_url.blank? 
  end
    
  def logo_small
    '<img itemprop="image" src="/images/school/' + picfoldernum + '/logo-small.png" />'
  end
  
  def logo_med
    '<img src="/images/school/' + picfoldernum + '/logo-med.png" />'
  end
  
  def logo_large
    '<img src="/images/school/' + picfoldernum + '/logo-large.png" />'
  end  
  
  def photo_small
    '<img src="/images/school/' + picfoldernum + '/photo-small.jpg" />'
  end
  
  def photo_med
    '<img src="/images/school/' + picfoldernum + '/photo-med.jpg" />'
  end  
  
  def photo_large
    '<img src="/images/school/' + picfoldernum + '/photo-large.jpg" />'
  end  
  
  def picfoldernum
    self.ipeds_id.blank? ? @num = self.id.to_s : @num = self.ipeds_id.to_s
    return @num 
  end
  
  def good_to_go
    @program = Program.find(:first, :conditions => ['is_online = 1 AND (good_to_go IS NULL OR good_to_go = 0) and school_id = ?', self.id])
    @program.blank? ? true : false
  end
  
  def tuition_chart
    
    @max = 0 
    @max = self.tuition_undergrad_09_in_state if self.tuition_undergrad_09_in_state > @max 
    @max = self.tuition_undergrad_09_out_of_state if self.tuition_undergrad_09_out_of_state > @max 
    @max = self.tuition_grad_09_in_state if self.tuition_grad_09_in_state > @max 
    @max = self.tuition_grad_09_out_of_state if self.tuition_grad_09_out_of_state > @max 
    @max = @max + 1000
    @url = 'http://chart.apis.google.com/chart?'
    @url += 'chxl=0:|Graduate+Tuition|Undergraduate+Tuition|1:'
      (0..@max).step(2000).each {|x| @url << '|%24' + (x/1000).to_s + 'k'}
    @url += '&chxp=1,'
      (0..@max).step(2000).each {|x| @url << x.to_s + ','}
    @url += '&chxr=0,0,55|1,0,' + @max.to_s
    @url += '&chxs=0,000000,11.5,0,l,777777|1,000000,12.5,0,lt,777777'
    @url += '&chxt=y,x'  
    @url += '&chbh=a,2,10'
    @url += '&chs=600x225'
    @url += '&cht=bhg'
    @url += '&chco=225094,ef800c'
    @url += '&chf=bg,s,FFFFFF00|b0,lg,0,356da6,0,225094,1|b1,lg,0,f9b85a,0,ef800c,1'
    @url += '&chd=t:' + ((self.tuition_grad_09_in_state.to_f/@max)*100.0).round().to_s + ',' + ((self.tuition_undergrad_09_in_state.to_f/@max)*100.0).round().to_s 
      @url += '|' + ((self.tuition_grad_09_out_of_state.to_f/@max)*100.0).round().to_s + ',' + ((self.tuition_undergrad_09_out_of_state.to_f/@max)*100.0).round().to_s
    @url += '&chdl=In-State|Out-of-State'
    @url += '&chdlp=t'
    '<img src="' + @url + '" alt="' + self.name + ' Tuition Costs" />'  
  end
  
  
  def expenses_chart
    
    @max = 0 
    @max = self.total_expense_09_in_state_on_campus if self.total_expense_09_in_state_on_campus > @max 
    @max = self.total_expense_09_out_of_state_on_campus if self.total_expense_09_out_of_state_on_campus > @max 
    @max = self.total_expense_09_in_state_off_campus if self.total_expense_09_in_state_off_campus > @max 
    @max = self.total_expense_09_in_state_off_campus_with_family if self.total_expense_09_in_state_off_campus_with_family > @max 
    @max = self.total_expense_09_out_of_state_off_campus if self.total_expense_09_out_of_state_off_campus > @max 
    @max = self.total_expense_09_out_of_state_off_campus_with_family if self.total_expense_09_out_of_state_off_campus_with_family > @max 

    @max = @max + 1000
    @url = 'http://chart.apis.google.com/chart?'
    @url += 'chxl=0:|Living+Off+Campus+with+Family|Living+Off+Campus|Living+On+Campus|1:'
      (0..@max).step(5000).each {|x| @url << '|%24' + (x/1000).to_s + 'k'}
    @url += '&chxp=1,'
      (0..@max).step(5000).each {|x| @url << x.to_s + ','}
    @url += '&chxr=0,0,55|1,0,' + @max.to_s
    @url += '&chxs=0,000000,11.5,0,l,777777|1,000000,12.5,0,lt,777777'
    @url += '&chxt=y,x'  
    @url += '&chbh=a,2,10'
    @url += '&chs=600x225'
    @url += '&cht=bhg'
    @url += '&chco=225094,ef800c'
    @url += '&chf=bg,s,77777700|b0,lg,0,356da6,0,225094,1|b1,lg,0,f9b85a,0,ef800c,1'
    @url += '&chd=t:' + ((self.total_expense_09_in_state_off_campus_with_family.to_f/@max)*100.0).round().to_s + ',' + ((self.total_expense_09_in_state_off_campus.to_f/@max)*100.0).round().to_s + ',' + ((self.total_expense_09_in_state_on_campus.to_f/@max)*100.0).round().to_s   
      @url += '|' + ((self.total_expense_09_out_of_state_off_campus_with_family.to_f/@max)*100.0).round().to_s + ',' + ((self.total_expense_09_out_of_state_off_campus.to_f/@max)*100.0).round().to_s + ',' + ((self.total_expense_09_out_of_state_on_campus.to_f/@max)*100.0).round().to_s   
    @url += '&chdl=In-State|Out-of-State'
    @url += '&chdlp=t'
    @url += '&chtt=Estimated+Total+Costs+Per+Year'
    '<img src="' + @url + '" alt="' + self.name + ' Total Costs" />'  
  end  


  def sat_chart 
    @max = 0 
    @max = self.sat_cr_25 if self.sat_cr_25 > @max 
    @max = self.sat_cr_75 if self.sat_cr_75 > @max 
    @max = self.sat_math_25 if self.sat_math_25 > @max 
    @max = self.sat_math_75 if self.sat_math_75 > @max 
    @max = self.sat_writing_25 if self.sat_writing_25 > @max 
    @max = self.sat_writing_75 if self.sat_writing_75 > @max 
    
    @max = @max + 50
    @url = 'http://chart.apis.google.com/chart?'
    @url += 'chxl=0:|Reading|Math|Writing|1:'
      (0..@max).step(50).each {|x| @url << '|' + x.to_s}
    @url += '&chxp=1,'
      (0..@max).step(50).each {|x| @url << x.to_s + ','}
    @url += '&chxr=0,0,55|1,0,' + @max.to_s
    @url += '&chxs=0,000000,11.5,0,l,777777|1,000000,12.5,0,lt,777777'
    @url += '&chxt=y,x'  
    @url += '&chbh=a,2,10'
    @url += '&chs=600x225'
    @url += '&cht=bhg'
    @url += '&chco=225094,ef800c'
    @url += '&chf=bg,s,77777700|b0,lg,0,356da6,0,225094,1|b1,lg,0,f9b85a,0,ef800c,1'
    @url += '&chd=t:' + ((self.sat_writing_25.to_f/@max)*100.0).round().to_s + ',' + ((self.sat_math_25.to_f/@max)*100.0).round().to_s + ',' + ((self.sat_cr_25.to_f/@max)*100.0).round().to_s   
      @url += '|' + ((self.sat_writing_75.to_f/@max)*100.0).round().to_s + ',' + ((self.sat_math_75.to_f/@max)*100.0).round().to_s + ',' + ((self.sat_cr_75.to_f/@max)*100.0).round().to_s   
    @url += '&chdl=25th+Percentile|75th+Percentile'
    @url += '&chdlp=t'
    @url += '&chtt=SAT+Scores+of+Admitted+Students+by+Percentile'
    '<img src="' + @url + '" alt="' + self.name + ' SAT SCORES" />'  

  end


  def act_chart 
    @max = 0 
    @max = self.act_composite_25 if self.act_composite_25 > @max 
    @max = self.act_english_25 if self.act_english_25 > @max 
    @max = self.act_math_25 if self.act_math_25 > @max 
    @max = self.act_writing_25 if self.act_writing_25 > @max 
    @max = self.act_composite_75 if self.act_composite_75 > @max 
    @max = self.act_english_75 if self.act_english_75 > @max 
    @max = self.act_math_75 if self.act_math_75 > @max 
    @max = self.act_writing_75 if self.act_writing_75 > @max 

    @max = @max + 5
    
    @url = 'http://chart.apis.google.com/chart?'
    #@url += 'chxl=0:|Writing|Math|English|Composite|1:'
    @url += 'chxl=0:|Composite|English|Math|Writing|1:'
      (0..@max).step(2).each {|x| @url << '|' + x.to_s}
    @url += '&chxp=1,'
      (0..@max).step(2).each {|x| @url << x.to_s + ','}
    @url += '&chxr=0,0,55|1,0,' + @max.to_s
    @url += '&chxs=0,000000,11.5,0,l,777777|1,000000,12.5,0,lt,777777'
    @url += '&chxt=y,x'  
    @url += '&chbh=a,2,10'
    @url += '&chs=600x225'
    @url += '&cht=bhg'
    @url += '&chco=225094,ef800c'
    @url += '&chf=bg,s,77777700|b0,lg,0,356da6,0,225094,1|b1,lg,0,f9b85a,0,ef800c,1'
    @url += '&chd=t:' + ((self.act_writing_25.to_f/@max)*100.0).round().to_s + ',' + ((self.act_math_25.to_f/@max)*100.0).round().to_s + ',' + ((self.act_english_25.to_f/@max)*100.0).round().to_s  + ',' + ((self.act_composite_25.to_f/@max)*100.0).round().to_s    
      @url += '|' + ((self.act_writing_75.to_f/@max)*100.0).round().to_s + ',' + ((self.act_math_75.to_f/@max)*100.0).round().to_s + ',' + ((self.act_english_75.to_f/@max)*100.0).round().to_s + ',' + ((self.act_composite_75.to_f/@max)*100.0).round().to_s      
    @url += '&chdl=25th+Percentile|75th+Percentile'
    @url += '&chdlp=t'
    @url += '&chtt=ACT+Scores+of+Admitted+Students+by+Percentile'
    '<img src="' + @url + '" alt="' + self.name + ' ACT SCORES" />'  

  end

  def top_rated_professors
    @c = Crawlschool.find(:first, :conditions => ['school_id = ? AND url like ?', self.id, '%' + 'ratemy' + '%'])
    if @c
      Crawlprof.find(:all, :limit => 10, :order => 'overall_quality DESC', :conditions => ['crawlschool_id = ?', @c.id])
    else
      return nil
    end
  end




end
