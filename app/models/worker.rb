class Worker 


  def self.clean_content_display(content)
    
    #check for all caps and fix
    @words = content.split
    if @words.length > 1
      @ct = 0
      for word in @words
        @ct = @ct + 1 if word.index(/[A-Z][A-Z][A-Z]/)
      end
      if @ct > 1
        @new = []
        @words.each {|x| @new << x.capitalize}  
        content = @new.join(' ')
      end
    end
    #clean the content
    content = content.strip.gsub(/OR$/,'')
    content = content.gsub('?','')
    return content
  end

  def self.not_na(content)
    if content.index(/^\s*n(\/|\\)*a/i) || content.index("1/2")
      return false
    else
      return true
    end
    
  end

  def self.all_programs_from_school(programs, school) 
    @output = []
    for program in programs
      @output << program if program.school_id == school.id and program.inactive != true
    end
    return @output
  end

  def self.online_subject_programs(subject=nil, lim=nil) 
    if lim.blank?
      Program.find(:all, :conditions => ['is_online = true AND inactive IS NULL and subjects.id = ?', subject.id], :include => [:subjects])
    else
      Program.find(:all, :limit => lim, :conditions => ['is_online = true AND inactive IS NULL and subjects.id = ?', subject.id], :include => [:subjects])    
    end
  end

  def self.online_subject_programs_in_degreelevel_id(subject=nil, degreelevel_id=nil) 
    #Program.find(:all, :conditions => ['is_online = true AND inactive IS NULL and subjects.id = ? and degreelevels.id = ?', subject.id, degreelevel_id], :include => [:subjects, :degreelevels])
    
    @ps = Program.find(:all, :conditions => ['is_online = true AND inactive IS NULL and subjects.id = ?', subject.id], :include => [:subjects])
    @tin = []
    for p in @ps
      @tin << p if p.degreelevels.first.id == 69
    end
    return @tin
  end

  def self.online_schools_from_online_programs(programs)
    @school_ids = []
    programs.each {|p| @school_ids << p.school_id}
    @school_ids.uniq!
    @schools = []
    for s in @school_ids
      @schools << School.find_by_id(s)
    end 
    @schools.sort! {|a,b| b.priority <=> a.priority}  
  end

  def self.asset_host(num)
    if RAILS_ENV == 'development'
      return ''
    else
      return 'http://assets' + num.to_s + '.onlineeducation.net'
    end
  end

  def self.make_paragraph(sentences, themodels)
    
    #GET THE SENTENCE PATH -- @base4_array -- from the model id from the model with the greatest count
    @ms = ['City', 'Profession', 'Subject', 'Degreelevel', 'State']
    @found_one = false
    for m in @ms
      for themodel in themodels 
        if Worker.get_model_name(themodel) == m and @found_one == false
          @base4_array = Worker.get_base_4_array(themodel.id % 255)
          @found_one = true
        end
      end  
    end
    
    #Construct the @paragraph
    @paragraph = ''
    @ct = 0
    if !@base4_array.blank? and !sentences.blank? 
      for sentence in sentences
        @paragraph += sentence.body + ' ' if @base4_array[@ct] == 0
        @paragraph += sentence.spins.first.body + ' ' if @base4_array[@ct] == 1
        @paragraph += sentence.spins.second.body + ' ' if @base4_array[@ct] == 2
        @paragraph += sentence.spins.third.body + ' ' if @base4_array[@ct] == 3
        @ct = @ct + 1
      end
    end
    
    #replacements !!! 
    @modelnames = []
    themodels.each {|m| @modelnames << Worker.get_model_name(m)}
    
    if @paragraph.index(/profession/i) and (@pos = @modelnames.index('Subject')) and !@modelnames.index('Profession')
       themodels << themodels[@pos].professions.first
    end
    
    if @paragraph.index(/subject/i) and (@pos = @modelnames.index('Profession')) and !@modelnames.index('Subject')
       themodels << themodels[@pos].subjects.first
    end

    if @paragraph.index(/state/i) and (@pos = @modelnames.index('City')) and !@modelnames.index('State')
       themodels << themodels[@pos].state
    end

    #first convert the models
    @paragraph = Worker.general_model_subs(@paragraph, themodels)
    
    #next swap the replacements. 
    @paragraph = Worker.swap_in_replacements(@paragraph, themodels)
    
    #finally swap in the links
    
    return @paragraph 

  end
  
  def self.swap_in_replacements(thecontent, themodels)
    
    
    @modelnames = []
    themodels.each {|m| @modelnames << Worker.get_model_name(m)}
    
    @replacement_names = []
    if @s_pos = @modelnames.index('Subject')
      @replacement_names = @replacement_names + ['subject.description',
      'subject.common_job_tasks',
      'subject.organizations',
      'subject.related_subjects',
      'subject.currently_in_demand_professions',
      'subject.common_entry_level_professions',
      'subject.journals_and_magazines',
      'subject.top_employment_cities',
      'subject.top_employment_states',
      'subject.common_degree_programs',
      'subject.common_course_titles',
      'profession.character_traits',
      'profession.low_salary',
      'profession.high_salary',
      'profession.average_salary',
      'profession.description',
      'profession.typical_work_locations',
      'profession.current_employment_rate',
      'profession.projected_employment_rate',
      'profession.negatives',
      'profession.positives',
      'profession.quotes',
      'profession.typical_length_of_schooling',
      'profession.length_of_initial_on_the_job_training', 
      'profession.average_gpa_to_land_the_job',
      'profession.consider_these_related_professions',
      'profession.common_interview_questions',
      'profession.common_collaborating_professions',
      'profession.training_books',
      'profession.popular_books',
      'profession.average_vacation_time', 
      'profession.average_work_hours_per_week', 
      'profession.average_years_working_job',
      'profession.best_to_work_for_companies',
      'profession.common_college_major_subjects']
    end
    
    if @modelnames.index('City')
      @replacement_names = @replacement_names + ['city.churches',
        'city.bars',
        'city.parks',
        'city.landmarks',
        'city.activities',
        'city.characteristics_of_the_people',
        'city.hospitals',
        'city.top_industries',
        'city.museums',
        'city.universities',
        'city.people_go_out_of_city_to_vacation_destinations',
        'city.hotels',
        'city.music_venues',
        'city.restaurants',
        'city.neighborhoods',
        'city.popular_events',
        'city.top_non_english_spoken_languages']
    end
    
    if @modelnames.index('State')
      @replacement_names = @replacement_names + ['state.song', 
        'state.flower', 
        'state.population', 
        'state.bird', 
        'state.nickname', 
        'state.motto', 
        'state.tree', 
        'state.name_of_residents', 
        'state.capital', 
        'state.climate',
        'state.top_national_parks',
        'state.famous_residents']
    end
    
    
  

      for subject_replacement_name in @replacement_names
        
        amodel = themodels[@modelnames.index('Subject').to_i] if subject_replacement_name.index(/^subject/i)
        amodel = themodels[@modelnames.index('City').to_i] if subject_replacement_name.index(/^city/i)
        amodel = themodels[@modelnames.index('State').to_i] if subject_replacement_name.index(/^state/i)
        amodel = themodels[@modelnames.index('Profession').to_i] if subject_replacement_name.index(/^profession/i)
        
        @replacement = nil 
        @r = /\[#{subject_replacement_name}\[(\d)\]\]*,*/i  
        @d = thecontent.gsub(/.*\[#{subject_replacement_name}\[(\d)\]\]*.*/,'\1')
        @goodtogo = true
        @goodtogo = false if @goodtogo == true and !subject_replacement_name.index(/#{Worker.get_model_name(amodel)}/i)
        @goodtogo = false if @goodtogo == true and !subject_replacement_name.last == 's' 
        @goodtogo = false if @goodtogo == true and @d.blank?
        if @goodtogo == true and @replacement = Replacement.find(:first, :conditions => ['name = ? and replaceable_id = ?', subject_replacement_name, amodel.id]) 
    
        else
          @goodtogo = false 
          #here is where you should do the gsub to delete the unused one
          thecontent = thecontent.gsub(@r, '')
          
        end
        @goodtogo = false if @goodtogo == true and !@replacement || @replacement.body.nil?
        

        if @goodtogo == true   
          
          @thenums = thecontent.scan(@r)
          for num in @thenums
            @new_r = /\[#{subject_replacement_name}\[(#{num})\]\]*/i
            @replacing = @replacement.body[(num[0]).to_s].strip if !@replacement.body[(num[0]).to_s].blank?
            @replacing = '' if @replacing.blank? 
            
            @for_i = ['subject.journals_and_magazines',
              'profession.common_interview_questions',
              'subject.common_course_titles',
              'profession.training_books',
              'profession.popular_books']
            
            if @for_i.index(subject_replacement_name)
              @replacing = '<i>' + @replacing + '</i>'
            else
              @replacing = @replacing.gsub(/\?/,'') 
            end
            
            #maybe a thing to check for all caps
            @words = @replacing.split
            if @words.length > 1
              @ct = 0
              for word in @words
                @ct = @ct + 1 if word.index(/[A-Z][A-Z][A-Z]/)
              end
              if @ct > 1
                @new = []
                @words.each {|x| @new << x.capitalize}  
                @replacing = @new.join(' ')
              end
            end
            
            
            thecontent = thecontent.gsub(@new_r, @replacing) if !@replacement.body[(num[0]).to_s].blank?
            
            
          end
          
        end
          
          
        #its a single replacement ?           
        @r = /\[#{subject_replacement_name}\]/i
        @ngoodtogo = true
        @ngoodtogo = false if !thecontent.index(@r)
        
        #thecontent = 'sdfsdfsf' if subject_replacement_name == 'profession.projected_employment_rate'
        
        if @ngoodtogo == true and @replacement = Replacement.find(:first, :conditions => ['name = ? and replaceable_id = ?', subject_replacement_name, amodel.id]) 
          if @replacement and !@replacement.body.blank?
            @replacing = @replacement.body
            
            #salary fixes 
            if subject_replacement_name.index(/salary/)
              @num = @replacing.to_i
              @num = @num * 1000
              @num = 15000 if @num < 15000
              @num = 500000 if @num > 500000
              @replacing = @num.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")  
            end
            
            
            thecontent = thecontent.gsub(@r, @replacing) 
          end
        else
          thecontent = thecontent.gsub(/\[#{subject_replacement_name}\],*/i,'')
        end
                          
    end
    
    
    
    
    #TESTING
    #themodels = [Profession.find_by_name('writer')]
    #subject_replacement_name = 'profession.current_employment_rate'
    #@r = /\[#{subject_replacement_name}\]/
    #thecontent = 'there is a dude [profession.current_employment_rate],  [profession.current_employment_rate],  [subject.common_course_titles[1]]'
    #amodel=Profession.find_by_name('writer')

    @scans = thecontent.scan(/\{([^:]+?)\}/) 
    for scan in @scans
      thecontent = thecontent.gsub(/\{#{scan[0]}\}/,'<a href="/' + Worker.inurl(scan[0]) + '">' + scan[0] + "</a>")
    end
    #sub in links
    @scans = thecontent.scan(/\{(.+?)::(.+?)\}/) 
    for scan in @scans
      thecontent = thecontent.gsub(/\{#{scan[0]}::#{scan[1]}\}/,'<a href="/' + Worker.inurl(scan[1]) + '">' + scan[0] + "</a>")
    end
    

    
    #clean up the nonreplaced
    #thecontent = thecontent.gsub(/\[.+?\..+?\[\d\]\],*/,'')
    #thecontent = thecontent.gsub(/\[.+?\..+?\],*/,'')
    
    
    
    return thecontent     
  end
  
  def self.subthecontent(thecontent, modelname, inname)
    if inname.index(/^[A-Z][A-Z]/) || modelname == 'City' || modelname == 'State' || modelname == 'Degreelevel'
      thecontent = thecontent.gsub(/(\s|\{|^)a \[#{modelname}\]/i, '\1' + Worker.an_name(inname)) 
      thecontent = thecontent.gsub(/\[an_#{modelname}\]/i, Worker.an_name(inname)) 
      thecontent = thecontent.gsub(/\[#{modelname}\]/i, inname)      
    else
      thecontent = thecontent.gsub(/(\s|\{|^)A \[#{modelname}\]/, '\1' + Worker.an_name(inname)) 
      thecontent = thecontent.gsub(/\[an_#{modelname}\]/, Worker.an_name(inname)) 
      thecontent = thecontent.gsub(/\[#{modelname}\]/, inname)
    
      thecontent = thecontent.gsub(/(\s|\{|^)a \[#{modelname.downcase}\]/, '\1' + Worker.an_name(inname.downcase)) 
      thecontent = thecontent.gsub(/\[an_#{modelname.downcase}\]/, Worker.an_name(inname.downcase)) 
      thecontent = thecontent.gsub(/\[#{modelname.downcase}\]/, inname.downcase)
    end  
    
    return thecontent 
  end
  
  def self.general_model_subs(thecontent, themodels)

    @modelnames = []
    themodels.each {|m| @modelnames << Worker.get_model_name(m)}
        
    for m in themodels      
      @modelname = Worker.get_model_name(m)
      @inname = m.name
      thecontent = Worker.subthecontent(thecontent, @modelname, @inname)
    
      if thecontent.index(/profession/i) and @modelname == 'Subject' and !@modelnames.index('Profession') and !m.professions.blank? 
        @inname = m.professions.first.name
        @modelname = 'Profession'
        thecontent = Worker.subthecontent(thecontent, @modelname, @inname)
      end
      
      if thecontent.index(/subject/i) and @modelname == 'Profession' and !@modelnames.index('Subject')  
        @inname = m.opt_subjects.first.name
        @modelname = 'Subject'
        thecontent = Worker.subthecontent(thecontent, @modelname, @inname)
      end

      if thecontent.index(/state/i) and @modelname == 'City' and !@modelnames.index('State')  
        @inname = m.state.full_name
        @modelname = 'State'
        thecontent = Worker.subthecontent(thecontent, @modelname, @inname)
      end

      if thecontent.index(/featuredschool/i) and @modelname == 'Featuredprogram' and !@modelnames.index('Featuredschool')  
        @inname = m.featuredschool.name
        @modelname = 'Featuredschool'
        thecontent = Worker.subthecontent(thecontent, @modelname, @inname)
      end

    end
      
    return thecontent
  end  
  
  def self.get_model_name(m)
    return m.inspect.scan(/\#<(.+?)\s/)[0][0]
  end

  def self.get_base_4_array(num)
    @base10_num = num
    @base4_array = []
    @base = 4
    while @base10_num != 0
      @remainder = @base10_num % @base
      @base4_array << @remainder 
      @base10_num = @base10_num / @base  
    end
    while @base4_array.length < 4
      @base4_array << 0
    end
    return @base4_array
  end

  def self.cleanh1(h)
    h = h.gsub(/<\/span> /,'</span>')
    h = h.gsub(/AND UNIVERSITIES/,'&UNIVERSITIES')
    h = h.gsub(/CRIMINALJUSTICE/, 'CRIMINAL JUSTICE')
    h = h.gsub(/LIBERALARTS/, 'LIBERAL ARTS')
    h = h.gsub(/LIBERALARTS/, 'LIBERAL ARTS')
    h = h.gsub(/IN</, 'IN <')
    return h
  end
  
  def self.an_name(q)
    @a = q.first
    if @a == 'a' || @a == 'e' || @a == 'i' || @a == 'o' || @a == 'u' || @a == 'A' || @a == 'E' || @a == 'I' || @a == 'O' || @a == 'U'
      return ' an ' + q  
    else
      if q == 'Herbalist'
        return ' an ' + q 
      else
        return ' a ' + q    
      end
    end
  end
  
  def self.inurl(q)
    q.downcase.gsub(/(\s|\.|'|\/|\(|\)|&|,)/,'-').gsub(/\?/,'')
    
  end

  def self.unurl(q)
    
    @output = q.gsub(/-/,' ')
    @output = @output.gsub(/k 12/i,'K-12')
    @output = @output.gsub(/x ray/i,'X-Ray')
    
    @caps = ''
    @output.split.each {|x| ['X-Ray','K-12'].index(x) ? @caps += x + ' ' : @caps += x.capitalize + ' '}
    @output = @caps.strip 
    
    @output
    
  end

  def self.auto_review_hits(sandbox='sandbox',htid=nil,page_size=100)

    if sandbox == 'sandbox'
      RTurk.setup(AWSAccessKeyId, AWSAccessKey, :sandbox => true)
    else
      RTurk.setup(AWSAccessKeyId, AWSAccessKey, :sandbox => false)      
    end
    
    #setup notification parameters
    @from = ['turk@wecreatecontent.info']
    @to = ['wsfilter@gmail.com']
    @emailbody = ''
    #setup optional parameters 
    @page_size = page_size
    @ht = Hittype.find(htid) if !htid.blank?
    @hittypeid = @ht.hittypeid if @ht

    #grab the latest 100 reviewable HITs, if any
    @raw = RTurk::GetReviewableHITs.create(:page_size => 1, :htid => @hittypeid)
    @total_num = @raw.raw_xml.scan(/<TotalNumResults>(.+?)<\/TotalNumResults>/)[0][0] if @raw.raw_xml and !@raw.raw_xml.scan(/<TotalNumResults>(.+?)<\/TotalNumResults>/).blank?
  
    if @total_num and @total_num.to_i > 0 
      
      if @total_num.to_i > @page_size
        @raw = RTurk::GetReviewableHITs.create(:page_size => @page_size, :htid => @hittypeid, :page_number => rand((@total_num.to_i/@page_size))+1 )
      else
        @raw = RTurk::GetReviewableHITs.create(:page_size => @page_size, :htid => @hittypeid)  
      end
    
    end
  
    #@onthispage_num = @raw.raw_xml.scan(/<NumResults>(.+?)<\/NumResults>/)[0][0] if @raw.raw_xml and !@raw.raw_xml.scan(/<NumResults>(.+?)<\/NumResults>/).blank?
    @aws_hits = @raw.hit_ids.inject([]) do |arr, hit_id|
      arr << RTurk::Hit.new(hit_id); arr;
    end  

    for aws_hit in @aws_hits

  	  # does this HIT have any 'submitted' assignments?  If not, it should be disposed
  	  @has_a_submitted = false
  	  aws_hit.assignments.each {|x| @has_a_submitted = true if x.status == 'Submitted'}
      if @has_a_submitted == true
        for assignment in aws_hit.assignments
          #only work on "Submitted" assignments
          if assignment.status == 'Submitted'
            
            @aws_hit = aws_hit
  				  @our_hit = Hit.find_by_hitid(aws_hit.id) 
  				  if !@our_hit.blank?
  				    @our_hittype = @our_hit.hittype 
	            @nogo = false 
	            @turker = Turker.find(:first, :conditions => ['worker_id = ?', assignment.worker_id]) 
	          else
	            @nogo = true
	            @no_hit = true
	          end

					  
					  #----figure out how to handle the assignment data based on hittype action_type

   		      # determine if this is a paragraph written by a worker with more than 2 clean hits of this hittype
  		      if @nogo == false
  		        @clean_num = 0
  		        @clean_hits = Hit.find(:all, :conditions => ['hittype_id = ? and approved_worker_id = ? and (edited IS NULL OR edited = ?)', @our_hittype.id, assignment.worker_id, false])
  		        for clean_hit in @clean_hits
  		          @clean_num = @clean_num + 1 if !Replacement.find(:first, :conditions => ['hit_id = ? and reviewed = ?', clean_hit.id, true]).blank? 
  		        end
  		        if @clean_num > 2 
	          
  		          #automatically approve the assignment
            	  #first save this as a replacement
            	  if @our_hittype.action_type != 'replacements_special'
              	  @r = Replacement.find(:first, :conditions => ['name = ? AND replaceable_id = ? AND replaceable_type = ?', @our_hittype.name, @our_hit.hittable_id, @our_hit.hittable_type]) if sandbox != 'sandbox'
              	  @r = Replacement.new if @r.blank? 
              	  @r.name = @our_hittype.name
            	  
              	  if @our_hittype.action_type == 'replacements_long'
              	    @r.body = assignment.answers['body']
              	    @emailbody += @r.body + '<br>'
              	  else
              	    #build the hash
              	    @ct = 1
              	    @theentries = {}
              	    while @ct <= 10
              	      @theentries[(@ct-1).to_s] = assignment.answers['entries_' + @ct.to_s]     
              	      @ct = @ct + 1  
              	    end
              	    @r.body = @theentries
              	    @emailbody += @theentries.inspect + '<br>'  
              	  end
              	  
              	  @r.replaceable_id = @our_hit.hittable_id
              	  @r.replaceable_type = @our_hit.hittable_type 
              	  @r.sandbox = true if sandbox == 'sandbox'
              	  @r.reviewed = false
              	  @r.hit_id = @our_hit.id
              	  @r.hittype_id = @our_hittype.id
                  @r.save
              	  @emailbody += @r.name + '-' + @r.id.to_s + '<br><br>'
                  
                  
                else
                  
                  #special entries
                  @ct = 1
                  while !assignment.answers['e'+ @ct.to_s + '_name'].blank?
                    
                    @thename = assignment.answers['e'+ @ct.to_s + '_name']
                            
                    @r = nil                       
                	  @r = Replacement.find(:first, :conditions => ['name = ? AND replaceable_id = ? AND replaceable_type = ?', @thename, @our_hit.hittable_id, @our_hit.hittable_type]) if sandbox != 'sandbox'
                	  @r = Replacement.new if @r.blank? 
                	  @r.name = @thename
                	  @r.body = assignment.answers[@thename]   
                	  @emailbody += @r.body + '<br>'        
                	  @r.replaceable_id = @our_hit.hittable_id
                	  @r.replaceable_type = @our_hit.hittable_type 
                	  @r.sandbox = true if sandbox == 'sandbox'
                	  @r.reviewed = false
                	  @r.hit_id = @our_hit.id
                	  @r.hittype_id = @our_hittype.id
                    @r.save
                	  @emailbody += @r.name + '-' + @r.id.to_s + '<br><br>'                     
                                          
                    @ct = @ct + 1  
                  end
                  
                end

                #note the worker id and join it    
                @turker.hits << @our_hit
                @turker.ip = assignment.answers['ip']
                @turker.save
                @our_hit.approved_worker_id = assignment.worker_id
                @our_hit.status = 'Disposed'
                @our_hit.save
	            
                assignment.approve!

                #dispose the HIT - in this app if a HIT gets one approved assignment that's all we need 
                @aws_hit.dispose!	  

              end #if clean_hit > 2
            end #if no_go == false
  				  
          end #if assignment.status == 'Submitted'
        end #for assignment in aws_hit.assignments    
        
      else #if you're here the hit has no 'submitted' assignments because it expired and should be disposed
  		  aws_hit.dispose!
  		  @our_hit = Hit.find_by_hitid(aws_hit.id)
  		  @our_hit.status = 'Disposed'
  			@our_hit.save 
      end
    
    end #for aws_hit in @aws_hits
    
    Notifier::deliver_message(@from,@to,'Auto Approved HITs',@emailbody,true) if !@emailbody.blank? 
    
  end 
  
  
  def self.is_this_plagiarized?(c, ip=nil)
    #first split up the paragraph roughly into sentences 
    @a = c.split(/[\.|\!|\?]\s+?([A-Z])/)
    
    #construct the sentences array
    @sentences = []
    while @a.length > 0 
      if @a[0].length == 1
        sentence = @a[0] + @a[1]
        @sentences << sentence 
        @a.delete_at(0)
        @a.delete_at(0)
      else
        @sentences << @a[0]
        @a.delete_at(0)
      end
    end
    
    @unique = true
    for sentence in @sentences
      if @unique == true
        @url = 'http://ajax.googleapis.com/ajax/services/search/web?v=1.0'
        @url += '&userip=' + URI.escape(ip) if !ip.blank?         
        @url += '&q=' + URI.escape(sentence)

        @body = open(@url[0..2048]).read    
        @a = JSON.parse(@body) if @body 
        if !@a.blank? and !@a['responseData'].blank? and !@a['responseData']['results'].blank? 
          @content = @a['responseData']['results'].first['content'] 
          if @content.gsub(/<\/b>, <b>/,' ').gsub(/<\/b>. <b>/,' ').index(/<b>\s*?([^<|\s]+?\s){10}/)
            @unique = false
            @bad_sentence = sentence
            @ripped_url = @a['responseData']['results'].first['url']
          end
        end  
      end
    end
    
    @unique == true ? @thereturn = false : @thereturn = true
    
    return [@thereturn, @bad_sentence, @ripped_url]
    
  end

  def self.grab_page(url)
    require 'open-uri'
    open(url).read
  end

  def self.add_us_states
    @body = Worker.grab_page('http://www.usps.com/ncsc/lookups/abbr_state.txt')
    for num in 2..60
      @s = State.new
      @s.full_name = @body.to_a[num].split(/\s\s\s/).first
      @s.two_letter_code = @body.to_a[num].split(/\s\s\s/).last.strip
      @s.country = 'US'
      @s.save if !@s.full_name.blank? and !@s.two_letter_code.blank?
    end
  end
  
  def self.lowercase_the_states
    for state in State.all
      @a = []
      state.full_name.split.each {|x| @a << x.capitalize}
      state.full_name = @a.join(' ')
      state.save
    end
  end
  
  def self.ss
    #script to tag school with subject
    for n in 2079..5371
      school = School.find(n)
      @c = school.rawcn.gsub(/\n/,'').gsub(/\r/,'').scan(/Programs\/Majors<\/a>(.*?)<\/table>/) if !school.rawcn.blank?
      for subject in Subject.all
        if !@c.blank? and @c[0][0].index(/#{subject.name}/i)
          school.subjects << subject if subject.name.length > 4
        end
      end
    end    
  end
  
  def self.cache_main_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    #first knock out all the non [] pages 
    @pages = Page.find(:all, :conditions => ['url_string NOT LIKE ?', '%' + '[' + '%'])
    for page in @pages
      `wget -q -nc #{@url}#{page.url_string}`
      `rm #{page.url_string}`
    end
  end
  
  def self.create_main_pages_sitemap
    @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
    @f = File.open('public/sitemaps/top_pages.xml','w')
    @f << '<?xml version="1.0" encoding="UTF-8"?>
'
    @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'
    @f << '<url><loc>http://www.onlineeducation.net/' 
    @f << '</loc><lastmod>' + @date + '</lastmod></url>'

    @pages = Page.find(:all, :conditions => ['url_string NOT LIKE ?', '%' + '[' + '%'])
    for page in @pages
      @f << '<url><loc>http://www.onlineeducation.net/' 
      @f << page.url_string
      @f << '</loc><lastmod>' + @date + '</lastmod></url>'
    end
    @f << '</urlset>'
    @f.close 
  end
  
  
  
  def self.cache_cousin_pages
    
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for subject in Subject.all_prims_alpha_order

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-degrees` 
      `rm online-#{Worker.inurl(subject.name)}-degrees`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-programs` 
      `rm online-#{Worker.inurl(subject.name)}-programs`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-courses` 
      `rm online-#{Worker.inurl(subject.name)}-courses`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-classes` 
      `rm online-#{Worker.inurl(subject.name)}-classes`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-training` 
      `rm online-#{Worker.inurl(subject.name)}-training`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-colleges` 
      `rm online-#{Worker.inurl(subject.name)}-colleges`

      `wget -q -nc #{@url}online-#{Worker.inurl(subject.name)}-schools` 
      `rm online-#{Worker.inurl(subject.name)}-schools`

      `wget -q -nc #{@url}#{Worker.inurl(subject.name)}-certification` 
      `rm #{Worker.inurl(subject.name)}-certification`

      `wget -q -nc #{@url}#{Worker.inurl(subject.name)}` 
      `rm #{Worker.inurl(subject.name)}`

    end

    for profession in Profession.all

      `wget -q -nc #{@url}#{Worker.inurl(profession.name)}` 
      `rm #{Worker.inurl(profession.name)}`
  
    end

  end
    
  
  
  def self.create_newoe_sitemap
    @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
    @f = File.open('public/sitemaps/sitemap.xml','w')
    @f << '<?xml version="1.0" encoding="UTF-8"?>
'
    @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'
    @f << '<url><loc>http://www.onlineeducation.net</loc></url>'  
    @f << '<url><loc>http://www.onlineeducation.net/blog</loc></url>'  
    
    puts 'Making Cousins'
    @subjects = Subject.find(:all, :conditions => ['prim = 1 AND has_online_program = 1'])    
    for subject in @subjects
      @f << '<url><loc>http://www.onlineeducation.net/schools/' + Worker.inurl(subject.name) + '/online</loc></url>'      
      @f << '<url><loc>http://www.onlineeducation.net/programs/' + Worker.inurl(subject.name) + '/online</loc></url>'      
      @f << '<url><loc>http://www.onlineeducation.net/courses/' + Worker.inurl(subject.name) + '/online</loc></url>'      
      @f << '<url><loc>http://www.onlineeducation.net/certifications/' + Worker.inurl(subject.name) + '/online</loc></url>' if subject.has_online_cert == true  
      @f << '<url><loc>http://www.onlineeducation.net/subjects/' + Worker.inurl(subject.name) + '</loc></url>'      
    end
    
    puts 'Making Professions'
    for profession in Profession.all 
      if !profession.opt_subjects.blank? and profession.has_zocc == true
        @f << '<url><loc>http://www.onlineeducation.net/professions/' + Worker.inurl(profession.name) + '</loc></url>'          
      end
    end
    
    @f << '</urlset>'
    @f.close 
  end  


    def self.create_newoe_state_and_city_sitemaps
      @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")

      @ct = 1
      @in_ct = 1
      @f = File.open('public/sitemaps/city-state-subject-1.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
'
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'     
      for subject in Subject.all_prims_alpha_order
        if @ct % 20 == 0   
          @in_ct = @in_ct + 1 
          @f << '</urlset>'
          @f.close
          puts 'going on to ' + @ct.to_s
          @f = File.open('public/sitemaps/city-state-subject-' + @in_ct.to_s + '.xml','w')
          @f << '<?xml version="1.0" encoding="UTF-8"?>
'
          @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'                    
        end

        for state in State.all
          @f << '<url><loc>http://www.onlineeducation.net/schools/' + Worker.inurl(subject.name) + '/' + state.two_letter_code + '</loc></url>'           
        end

        for city in City.find(:all, :conditions => ['prim = 1'])
          @f << '<url><loc>http://www.onlineeducation.net/schools/' + Worker.inurl(subject.name) + '/' + city.state.two_letter_code + '/' + Worker.inurl(city.name) + '</loc></url>'           
        end    

        @ct = @ct + 1
      end

      @in_ct = @in_ct + 1 
      @f << '</urlset>'
      @f.close


      @f = File.open('public/sitemaps/city-state-subject-' + @in_ct.to_s + '.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
'
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'      
      for state in State.all
        @f << '<url><loc>http://www.onlineeducation.net/schools/all/' + state.two_letter_code + '</loc></url>'
      end

      for city in City.find(:all, :conditions => ['prim = 1'])
        @f << '<url><loc>http://www.onlineeducation.net/schools/all/' + city.state.two_letter_code + '/' + Worker.inurl(city.name) + '</loc></url>'
      end    

      @f << '</urlset>'
      @f.close      
    end






















  def self.create_blog_sitemap

    @date = Time.now
    @f = File.open('public/sitemaps/blog.xml','w')
    @f << '<?xml version="1.0" encoding="UTF-8"?>
'
    @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'
    for blog in Blog.all
      @f << '<url><loc>http://www.onlineeducation.net/' + blog.created_at.strftime("%Y") + '/' + blog.created_at.strftime("%m") + '/' + blog.created_at.strftime("%d") + '/' + blog.url_string + '</loc><lastmod>' + blog.updated_at.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00") + '</lastmod></url>'
    end
    @f << '</urlset>'
    @f.close
  end

  def self.create_cousins_sitemap
    @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
    @f = File.open('public/sitemaps/cousins.xml','w')
    @f << '<?xml version="1.0" encoding="UTF-8"?>
'
    @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'
    for subject in Subject.all_prims_alpha_order
      @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(subject.name) + '-degrees</loc><lastmod>' + @date + '</lastmod></url>'
      @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(subject.name) + '-programs</loc><lastmod>' + @date + '</lastmod></url>'
      @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(subject.name) + '-classes</loc><lastmod>' + @date + '</lastmod></url>'
      @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(subject.name) + '-schools</loc><lastmod>' + @date + '</lastmod></url>'
      @f << '<url><loc>http://www.onlineeducation.net/' + Worker.inurl(subject.name) + '</loc><lastmod>' + @date + '</lastmod></url>'
    end
    @f << '</urlset>'
    @f.close 
  end

  
  
    def self.create_qa_sitemap
      @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
      @f = File.open('public/sitemaps/qa.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
  '
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  '
      for q in Question.all_subject_templates
        for subject in Subject.all_prims_alpha_order
          @f << '<url><loc>http://www.onlineeducation.net' + q.url([subject]) + '</loc><lastmod>' + @date + '</lastmod></url>
'
        end
      end
      for q in Question.all_non_subject_templates
          @f << '<url><loc>http://www.onlineeducation.net' + q.url + '</loc><lastmod>' + @date + '</lastmod></url>
'      
      end    
      @f << '</urlset>'
      @f.close 
    end

  
  
  
    def self.create_degreelevels_city_state_sitemap
      @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
      @f = File.open('public/sitemaps/degreelevels-cities-and-states.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
  '
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  '
      for subject in Subject.all_prims_alpha_order
        for d in subject.degreelevels
          @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(d.name) + '-degree-in-' + Worker.inurl(subject.name) + '</loc><lastmod>' + @date + '</lastmod></url>' if Featuredprogram.find(:first, :conditions => ['degreelevels.name = ? and subjects.name = ?', d.name, subject.name], :include => [:degreelevels, :subjects])        
        end
      end
      for d in Degreelevel.all
        @f << '<url><loc>http://www.onlineeducation.net/online-' + Worker.inurl(d.name) + '-degree-programs</loc><lastmod>' + @date + '</lastmod></url>'
      end    
      for s in State.find(:all, :limit => 50)
        @f << '<url><loc>http://www.onlineeducation.net/colleges-in-' + Worker.inurl(s.full_name) + '</loc><lastmod>' + @date + '</lastmod></url>'
      end    
      for c in City.all
        @f << '<url><loc>http://www.onlineeducation.net/colleges-in-' + Worker.inurl(c.name) + '</loc><lastmod>' + @date + '</lastmod></url>'
      end    
      
      @f << '</urlset>'
      @f.close 
    end

  
  def self.cache_degreelevel_subject_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for subject in Subject.all_prims_alpha_order
      for d in subject.degreelevels
        `wget -q -nc #{@url}online-#{Worker.inurl(d.name)}-degree-in-#{Worker.inurl(subject.name)}` 
        `rm online-#{Worker.inurl(d.name)}-degree-in-#{Worker.inurl(subject.name)}`
      end
    end
  end
  
  
  def self.cache_degreelevel_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for d in Degreelevel.all
        `wget -q -nc #{@url}online-#{Worker.inurl(d.name)}-degree-programs` 
        `rm online-#{Worker.inurl(d.name)}-degree-programs`
    end    
  end
  
  def self.cache_state_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for s in State.find(:all, :limit => 50)
        `wget -q -nc #{@url}colleges-in-#{Worker.inurl(s.full_name)}` 
        `rm colleges-in-#{Worker.inurl(s.full_name)}`
    end    
  end
    
  def self.cache_city_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for c in City.all
        `wget -q -nc #{@url}colleges-in-#{Worker.inurl(c.name)}` 
        `rm colleges-in-#{Worker.inurl(c.name)}`
    end    
  end

  def self.cache_city_and_state_subject_pages
    @url = 'http://173.203.197.173/'
    Dir.chdir("tmp/precache")
    for subject in Subject.all_prims_alpha_order
      for state in State.find(:all, :limit => 50)
        `wget -q -nc #{@url}#{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(state.full_name)}` 
        `rm #{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(state.full_name)}`        
        for city in state.cities
          `wget -q -nc #{@url}#{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(city.name)}` 
          `rm #{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(city.name)}`
        end   
      end      
    end    
  end
  
  
  
    def self.create_state_and_city_sitemaps
      @date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
      
      @ct = 1
      @in_ct = 1
      @f = File.open('public/sitemaps/city-state-subject-1.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
'
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'     
      for subject in Subject.all_prims_alpha_order
        if @ct % 20 == 0   
          @in_ct = @in_ct + 1 
          @f << '</urlset>'
          @f.close
          @f = File.open('public/sitemaps/city-state-subject-' + @in_ct.to_s + '.xml','w')
          @f << '<?xml version="1.0" encoding="UTF-8"?>
'
          @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'                    
        end
         
        for state in State.find(:all, :limit => 50)
          @f << '<url><loc>http://www.onlineeducation.net/' + Worker.inurl(subject.name) + '-schools-in-' + Worker.inurl(state.full_name) + '</loc><lastmod>' + @date + '</lastmod></url>'           
        end
      
        for city in City.find(:all, :conditions => ['subjects.name = ?', subject.name], :include => [[:schools => :subjects]])
          @f << '<url><loc>http://www.onlineeducation.net/' + Worker.inurl(subject.name) + '-schools-in-' + Worker.inurl(city.name) + '</loc><lastmod>' + @date + '</lastmod></url>'          
        end    
        
        @ct = @ct + 1
      end
      
      @in_ct = @in_ct + 1 
      @f << '</urlset>'
      @f.close
      
      
      @f = File.open('public/sitemaps/city-state-subject-' + @in_ct.to_s + '.xml','w')
      @f << '<?xml version="1.0" encoding="UTF-8"?>
'
      @f << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'      
      for state in State.find(:all, :limit => 50)
        @f << '<url><loc>http://www.onlineeducation.net/colleges-in-' + Worker.inurl(state.full_name) + '</loc><lastmod>' + @date + '</lastmod></url>'
      end
      
      
      for city in City.all
        @f << '<url><loc>http://www.onlineeducation.net/colleges-in-' + Worker.inurl(city.name) + '</loc><lastmod>' + @date + '</lastmod></url>'
      end    
     
      
      @f << '</urlset>'
      @f.close      
    end

  
  
  def self.clear_subject_from_cache(subject=nil)
    
    if !subject.blank?
    
      #first clear from cousins 
      `rm public/cache/online-#{Worker.inurl(subject.name)}-degrees.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-programs.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-courses.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-classes.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-training.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-colleges.html`
      `rm public/cache/online-#{Worker.inurl(subject.name)}-schools.html`
      `rm public/cache/#{Worker.inurl(subject.name)}-certification.html`
      `rm public/cache/#{Worker.inurl(subject.name)}.html`
      `rm public/cache/#{Worker.inurl(subject.professions.first.name)}.html`

      #remove next from degreelevels
      for d in subject.degreelevels
        `rm public/cache/online-#{Worker.inurl(d.name)}-degree-in-#{Worker.inurl(subject.name)}.html`
      end
   
      #finally from city pages
      for state in State.find(:all, :limit => 50)
       `rm public/cache/#{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(state.full_name)}.html`        
        for city in state.cities
         `rm public/cache/#{Worker.inurl(subject.name)}-schools-in-#{Worker.inurl(city.name)}.html`
        end   
      end
    
    end
    
  end  
  
  
  def self.pcache
    
    @page = Page.find_by_url_string('[subject]-schools-in-[city]')
    @pageheadings = @page.pageheadings
    @models = []
    @city = City.find_by_name('seattle')
    @subject = Subject.find_by_name('nursing')
    
    @models << @city  
    @models << @subject 

    for pageheading in @pageheadings 
      @f = File.open('tmp/pcache/' + pageheading.id.to_s + 'c' + @city.id.to_s + 's' + @subject.id.to_s, 'w')
      @f << Worker.make_paragraph(pageheading.sentences, @models)
      @f.close
    end
    
  end
  
  def self.display_salary(num)
    @num = num.to_i
    @num = @num * 1000
    @num = 15000 if @num < 15000
    @num = 500000 if @num > 500000
    return @num.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")  
  end
  
  def self.r_grab_page(p)
    begin
      @theraw = Worker.grab_page(p)
      rescue
        ['no', 'no']
      else
        ['ok', @theraw]
    end    
  end
  
  def self.crawlprof

    @schools = Crawlschool.find(:all, :conditions => ['url LIKE ? AND id > ?', "%" + 'ratemypro' + "%", 1930])
    for school in @schools

      for letter in ("A".."Z")

        @status = 'no'
        while @status == 'no'
          @thetwo = Worker.r_grab_page(school.url + '&the_dept=All&orderby=TLName&letter=' + letter) 
          @status = @thetwo.first
          @raw = @thetwo.second
        end

        @result = @raw.scan(/<div class="profName"><a href="ShowRatings.jsp\?tid=(.*?)">(.*?)<\/a><\/div>.*?<div class="profDept">(.*?)<\/div>.*?<div class="profRatings">(.*?)<\/div>.*?<div class="profAvg">(.*?)<\/div>.*?<div class="profEasy">(.*?)<\/div>.*?<div class="profHot/im)

        if !@result.blank? and !@result[0].blank? and !@result[0][0].blank? 
          for result in @result
            @c = Crawlprof.new
            @c.url = result[0]
            @c.crawlschool_id = school.id
            @c.name = result[1]
            @c.department = result[2]
            @c.total_ratings = result[3]
            @c.overall_quality = result[4]
            @c.easiness = result[5]
            @c.save
          end  
        end

      end

    end
    
    
  end
  
  def self.snippet(thought, wordcount)
    thought.split[0..(wordcount-1)].join(" ") + (thought.split.size > wordcount ? "..." : "") 
  end

  def self.super_clean_snippet(thought, wordcount)
    @s = thought.split[0..(wordcount-1)].join(" ") + (thought.split.size > wordcount ? "..." : "") 
    @s.gsub(/\s/,'ZZZZZZZZ').gsub(/\./,'FFFFFFFF').gsub(/\W/,'').gsub('ZZZZZZZZ',' ').gsub('FFFFFFFF','.')
  end

  def self.is_not_blank(content)
    @good_to_go = true
    @good_to_go = false if @good_to_go == true and content.blank? 
    @good_to_go = false if @good_to_go == true and content.index(/^na\s*/i) 
    @good_to_go = false if @good_to_go == true and content.index(/^n\/a\s*/i) 
    @good_to_go = false if @good_to_go == true and content.index(/^n\\a\s*/i)
    return @good_to_go     
  end
  
  def self.random_string
    chars = ("A".."Z").to_a
    @s = Array.new(1, '').collect{chars[rand(chars.size)]}.join
    
    chars = ("1".."9").to_a
    @s += Array.new(2, '').collect{chars[rand(chars.size)]}.join

    chars = ("a".."z").to_a
    @s += Array.new(1, '').collect{chars[rand(chars.size)]}.join

    chars = ("A".."Z").to_a
    @s += Array.new(1, '').collect{chars[rand(chars.size)]}.join

    chars = ("a".."z").to_a
    @s += Array.new(1, '').collect{chars[rand(chars.size)]}.join
  end
  
  def self.grabz(name, content)
    
    @a = content.split("\n:")
    for x in @a
      @s = x.split(":")
      @thereturn = @s.second.gsub('"','') if @s.first == name
    end
    @thereturn.strip
  end
  
  def self.get_display_num_array(id=0)
    id = id % 10 
    @num = id
    @nums = [id]
    while @nums.length < 3
     @num = @num + 3
     if @num > 9
      @num = @num % 10    
     end  
     @nums << @num
    end
    return @nums
  end
  
  def self.is_online_cert(subject)
    Program.find(:first, :conditions => ['degreelevels.id = ? AND is_online = 1 and inactive IS NULL',69], :include => [:degreelevels])
  end
  
  def self.is_online_program(subject)
    Program.find(:first, :conditions => ['is_online = 1 and inactive IS NULL and subjects.id = ?',subject.id], :include => [:subjects])
  end
  def self.is_degreelevel_subject(degreelevel,subject)
    Program.find(:first, :conditions => ['is_online = 1 and inactive IS NULL and subjects.id = ? and degreelevels.id = ?',subject.id, degreelevel.id], :include => [:subjects, :degreelevels])
  end  
end







