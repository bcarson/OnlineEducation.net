class HomeController < ApplicationController

  skip_before_filter :verify_authenticity_token #, :only => [:livesearch, :contentsubmit, :update_map, :load_school_info_view, :load_courses, :contact_message_go, :leave_rating_go, :leave_comment_go, :matching_go, :load_yelp_listings]
  caches_page :index, :contact, :newswitchboard, :school

  def index
    @title = 'Education Database Online : Colleges, Universities, Schools, Courses, & Degrees'
    @description = 'Search, compare, and research information about local and online schools that have top programs, courses, and certificates in your field.'
  end

  def rankings
    @title = 'Education Database Online : Rankings'
    @description = 'Top rated online and campus schools - how we rank them based on a number of important factors.'
    @no_top_monetize_show = true
  end

  def about
    @title = 'About Education Database Online : Feature Guide'
    @description = 'Learn about Education Datbase Online and the features available to discover online and campus schools in your field of interest.'
    @page_phrase = 'Feature Guide'
    @no_top_monetize_show = true
  end

  def classroom_vs_online
    @title = 'Education Database Online : Classroom vs. Online'
    @description = 'Make an informed decision weighing the costs and benefits of on campus versus online universities and colleges.'
    @page_phrase = ''
    @no_top_monetize_show = true
  end

  def contact
    @title = 'Contact Us : Education Database Online'
    @description = 'Contact Education Database Online'
    @page_phrase = 'Contact Us'
    @no_top_monetize_show = true
  end


  def newswitchboard

    @subject_name = Worker.unurl(params[:subject_name]) unless params[:subject_name].blank?
    @city_name = Worker.unurl(params[:city_name]) unless params[:city_name].blank?
    @state_name = Worker.unurl(params[:state_name]) unless params[:state_name].blank?
    @cousin_name = Worker.unurl(params[:cousin_name]) unless params[:cousin_name].blank?

    case @cousin_name.downcase

      when 'schools'

        @no_top_monetize_show = true

        @page = Page.find_by_url_string('[subject]-schools-in-[city]') if @subject_name and @state_name and @city_name
        @page = Page.find_by_url_string('[subject]-schools-in-[state]') if @subject_name and @state_name and !@city_name
        @page = Page.find_by_url_string('colleges-in-[city]') if @subject_name == 'All' and @state_name and @city_name
        @page = Page.find_by_url_string('colleges-in-[state]') if @subject_name == 'All' and !@city_name and @state_name
        @page = Page.find_by_url_string('online-[Subject]-schools') if @subject_name and !@city_name and @state_name == 'Online'
        @page = Page.find_by_url_string('online-schools') if @subject_name == 'All' and !@city_name and @state_name == 'Online'

        if !@page.blank?
          @origin = {}
          case @page.url_string
            when '[Subject]-schools-in-[City]'
              @map_on = true
              @render_action = 'map_page'
              @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
              @state = State.find_by_two_letter_code(@state_name)
              @city = City.find(:first, :conditions => ['name = ? and prim = ? and state_id = ?', @city_name, true, @state.id ]) rescue nil
              if !@subject.blank? and !@state.blank? and !@city.blank?
                @origin['lat'] = @city.lat
                @origin['lng'] = @city.lng

                @schools = School.find(:all, :limit => 50, :order => 'rank DESC', :conditions => ['subjects.name = ? and schools.city_id = ? and schools.state_id = ?', @subject.name, @city.id, @state.id], :include => [:subjects])
                @total_schools_count = School.count(:conditions => ['subjects.name = ? and schools.city_id = ? and schools.state_id = ?', @subject.name, @city.id, @state.id], :include => [:subjects])
                if @total_schools_count == 0
                  @within = 100
                  @keepgoing = true
                  while @total_schools_count == 0 and @keepgoing == true
                    @schools = School.find(:all, :limit => 50, :origin =>[@city.lat,@city.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
                    if !@schools.blank?
                      @total_schools_count = School.count(:origin =>[@city.lat,@city.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
                    else
                      if @within == 100
                        @within = 500
                      else
                        @within += 500
                      end
                      if @within > 3000
                        @keepgoing = false
                      end
                    end
                  end
                end
                @redirect = true if @schools.blank?
                @online_programs = Worker.online_subject_programs(@subject) rescue nil
                @online_schools = Worker.online_schools_from_online_programs(@online_programs) rescue nil
              else
                @redirect = true
              end
            when '[Subject]-schools-in-[State]'
              @map_on = true
              @render_action = 'map_page'
              @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
              @state = State.find_by_two_letter_code(@state_name)
              if !@subject.blank? and !@state.blank?
                @origin['lat'] = @state.lat
                @origin['lng'] = @state.lng
                @schools = School.find(:all, :limit => 50, :order => 'rank DESC', :conditions => ['subjects.name = ? and schools.state_id = ?', @subject.name, @state.id], :include => [:subjects])
                @total_schools_count = School.count(:conditions => ['subjects.name = ? and schools.state_id = ?', @subject.name, @state.id], :include => [:subjects])
                if @total_schools_count == 0
                  @within = 100
                  @keepgoing = true
                  while @total_schools_count == 0 and @keepgoing == true
                    @schools = School.find(:all, :limit => 50, :origin =>[@state.lat,@state.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
                    if !@schools.blank?
                      @total_schools_count = School.count(:origin =>[@state.lat,@state.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
                    else
                      if @within == 100
                        @within = 500
                      else
                        @within += 500
                      end
                      if @within > 3000
                        @keepgoing = false
                      end
                    end
                  end
                end
                @redirect = true if @schools.blank?
                @online_programs = Worker.online_subject_programs(@subject) rescue nil
                @online_schools = Worker.online_schools_from_online_programs(@online_programs) rescue nil
              else
                @redirect = true
              end
            when 'colleges-in-[city]'
              @map_on = true
              @render_action = 'map_page'
              @state = State.find_by_two_letter_code(@state_name)
              @city = City.find(:first, :conditions => ['name = ? and prim = ? and state_id = ?', @city_name, true, @state.id]) rescue nil
              if !@city.blank?
                @origin['lat'] = @city.lat
                @origin['lng'] = @city.lng
                @schools = School.find(:all, :limit => 50, :order => 'rank DESC', :conditions => ['city_id = ? and state_id = ?', @city.id, @state.id])
                @total_schools_count = School.count(:conditions => ['city_id = ?', @city.id])
                if @total_schools_count == 0
                  @within = 100
                  @keepgoing = true
                  while @total_schools_count == 0 and @keepgoing == true
                    @schools = School.find(:all, :limit => 50, :origin =>[@city.lat,@city.lng], :within=>@within, :order => 'rank DESC')
                    if !@schools.blank?
                      @total_schools_count = School.count(:all, :origin =>[@city.lat,@city.lng], :within=>@within, :order => 'rank DESC')
                    else
                      if @within == 100
                        @within = 500
                      else
                        @within += 500
                      end
                      if @within > 3000
                        @keepgoing = false
                      end
                    end
                  end
                end
                @redirect = true if @schools.blank?
              else
                @redirect = true
              end
            when 'colleges-in-[state]'
              @map_on = true
              @render_action = 'map_page'
              @state = State.find(:first, :conditions => ['two_letter_code = ?', @state_name])
              if !@state.blank?
                @origin['lat'] = @state.lat
                @origin['lng'] = @state.lng
                @schools = School.find(:all, :limit => 50, :order => 'rank DESC', :conditions => ['state_id = ?', @state.id])
                @total_schools_count = School.count(:conditions => ['state_id = ?', @state.id])
              else
                @redirect = true
              end
            when 'online-[Subject]-schools'
              @no_top_monetize_show = true
              @render_action = 'cousin_subject'
              @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
              if !@subject.blank?
                @programs = Worker.online_subject_programs(@subject)
                @schools = Worker.online_schools_from_online_programs(@programs)
                @online_schools = @schools
                @online_programs = @programs
              end
              @redirect = true if @schools.blank?
          when 'online-schools'
              @render_action = 'cousin'
            #end when statements
          end
          unless @redirect == true
            @subarray = []
            @subarray << @subject if !@subject.blank?
            @subarray << @city if !@city.blank?
            @subarray << @state if !@state.blank?
            @title = Worker.general_model_subs(@page.title,@subarray)
            @description = Worker.general_model_subs(@page.description, @subarray)
            @no_top_monetize_show = true if !@subject.blank? and @online_schools.blank?

            if @render_action == 'map_page'
              @nearby_cities = City.find(:all, :conditions => ['prim = ?', true], :origin =>[@origin['lat'],@origin['lng']], :within=>100, :order => 'distance asc')
              @nearby_cities = @nearby_cities[0..30]
              @nearby_states = State.find(:all, :origin =>[@origin['lat'],@origin['lng']], :within=>1000, :order => 'distance asc')
              @nearby_states = @nearby_states[0..9]
            end

            render :action => @render_action
          else
            redirect_to '/', :status => 301
          end
        else
          redirect_to '/', :status => 301
        end
      #END WHEN 'SCHOOLS'

      when 'courses'
        @page = Page.find_by_url_string('online-[subject]-courses') if @subject_name and !@city_name and @state_name == 'Online'
        @page = Page.find_by_url_string('online-courses') if @subject_name == 'All' and !@city_name and @state_name == 'Online'
        if !@page.blank?
          case @page.url_string
            when 'online-[subject]-courses'
              @no_top_monetize_show = true
              @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
              if !@subject.blank?
                #@schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['subjects.name = ? and schools.is_online = ?', @subject.name, true], :include => [:subjects])
                @programs = Worker.online_subject_programs(@subject,lim=20)
                @schools = Worker.online_schools_from_online_programs(@programs)
                @online_schools = @schools
                @online_programs = @programs
                @render_action = 'cousin_subject'
                 @redirect = true if @schools.blank?
              else
                @redirect = true
              end
            #end when 'online-[Subject]-courses'
            when 'online-courses'
              @render_action = 'cousin'
              @schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['is_online = ?', true])
            #end  when 'online-[Subject]-courses'
          end #case
          unless @redirect == true
            @subarray = []
            @subarray << @subject if !@subject.blank?
            @title = Worker.general_model_subs(@page.title,@subarray)
            @description = Worker.general_model_subs(@page.description, @subarray)
            render :action => @render_action
          else
            redirect_to '/', :status => 301
          end
        else
          redirect_to '/', :status => 301
        end
      #END WHEN 'Courses'


    when 'programs'
      @page = Page.find_by_url_string('online-[subject]-programs') if @subject_name and !@city_name and @state_name == 'Online'
      @page = Page.find_by_url_string('online-programs') if @subject_name == 'All' and !@city_name and @state_name == 'Online'
      if !@page.blank?
        case @page.url_string
          when 'online-[subject]-programs'
            @no_top_monetize_show = true
            @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
            if !@subject.blank?
              #@schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['subjects.name = ? and schools.is_online = ?', @subject.name, true], :include => [:subjects])
              @programs = Worker.online_subject_programs(@subject,lim=20)
              @schools = Worker.online_schools_from_online_programs(@programs)
              @online_schools = @schools
              @online_programs = @programs
              @render_action = 'cousin_subject'
              @redirect = true if @schools.blank?
            else
              @redirect = true
            end
          #end when 'online-[Subject]-courses'
          when 'online-programs'
            @render_action = 'cousin'
            @schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['is_online = ?', true])
            #@redirect = true if @schools.blank?
          #end  when 'online-[Subject]-courses'
        end #case
        unless @redirect == true
          @subarray = []
          @subarray << @subject if !@subject.blank?
          @title = Worker.general_model_subs(@page.title,@subarray)
          @description = Worker.general_model_subs(@page.description, @subarray)
          render :action => @render_action
        else
          redirect_to '/', :status => 301
        end
      else
        redirect_to '/', :status => 301
      end
    #END WHEN 'Programs'






  when 'certifications'
    @page = Page.find_by_url_string('[Subject]-certification') if @subject_name and !@city_name and @state_name == 'Online'
    @page = Page.find_by_url_string('online-certifications') if @subject_name == 'All' and !@city_name and @state_name == 'Online'
    if !@page.blank?
      case @page.url_string
        when '[Subject]-certification'
          @no_top_monetize_show = true
          @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @subject_name, true])
          if !@subject.blank?
            #@schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['subjects.name = ? and schools.is_online = ?', @subject.name, true], :include => [:subjects])
            @programs = Worker.online_subject_programs_in_degreelevel_id(@subject, 69)
            @schools = Worker.online_schools_from_online_programs(@programs)
            @online_schools = @schools
            @online_programs = @programs
            @render_action = 'cousin_subject'
             @redirect = true if @schools.blank?
          else
            @redirect = true
          end
        #end when 'online-[Subject]-courses'
        when 'online-certifications'
          @render_action = 'cousin'
          @schools = School.find(:all, :limit => 20, :order => 'priority DESC', :conditions => ['is_online = ?', true])
        #end  when 'online-[Subject]-courses'
      end #case
      unless @redirect == true
        @subarray = []
        @subarray << @subject if !@subject.blank?
        @title = Worker.general_model_subs(@page.title,@subarray)
        @description = Worker.general_model_subs(@page.description, @subarray)
        render :action => @render_action
      else
        redirect_to '/', :status => 301
      end
    else
      redirect_to '/', :status => 301
    end
    #END WHEN 'certifications'


    else #no cousin_name match
      redirect_to '/', :status => 301
    end

  end



 def professions
    @cousin_name = 'Professions'
    if params[:profession_name].blank?
      @page = Page.find_by_url_string('careers')
    else
      @page = Page.find_by_url_string('[Profession]')
    end

    if !@page.blank?
      case @page.url_string
        when '[Profession]'
          @no_top_monetize_show = true
          @profession = Profession.find(:first, :conditions => ['professions.name = ?', Worker.unurl(params[:profession_name])])
          @subject = @profession.opt_subjects.first if @profession and !@profession.opt_subjects.blank?
          if !@profession.blank?
            if !@subject.blank?
              @programs = Worker.online_subject_programs(@subject,lim=20)
              @schools = Worker.online_schools_from_online_programs(@programs)
              @online_schools = @schools
              @online_programs = @programs
              @render_action = 'profession'
               @redirect = true if @schools.blank?
            else
              @redirect = true
            end
          else
            @redirect = true
          end
        #end when '[Profession]'
        when 'careers'
          @professions = Profession.find(:all, :order => 'professions.name', :conditions => ['subjects.prim = ?',  true], :include => [:subjects])
          @render_action = 'professions'
        #end  when 'careers'
      end #case
      unless @redirect == true
        @subarray = []
        @subarray << @profession if @profession
        @title = Worker.general_model_subs(@page.title,@subarray)
        @description = Worker.general_model_subs(@page.description, @subarray)
        render :action => @render_action
      else
        redirect_to '/', :status => 301
      end
    else
      redirect_to '/', :status => 301
    end
  end


  def subjects
    @cousin_name = 'Subjects'
    if !params[:subject_name].blank?
      @page = Page.find_by_url_string('[Subject]')
    else
      @page = Page.find_by_url_string('subjects')
    end
    if !@page.blank?
      case @page.url_string
        when '[Subject]'
          @no_top_monetize_show = true
          @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', Worker.unurl(params[:subject_name]), true])
          if !@subject.blank?
            @programs = Worker.online_subject_programs(@subject,lim=20)
            @schools = Worker.online_schools_from_online_programs(@programs)
            @online_schools = @schools
            @online_programs = @programs

            @render_action = 'subject'
             @redirect = true if @schools.blank?
          else
            @redirect = true
          end
        #end when 'online-[Subject]-courses'
        when 'subjects'
          @subjects = Subject.all_prims_alpha_order
          @render_action = 'subjects'
        #end  when 'online-[Subject]-courses'
      end #case
      unless @redirect == true
        @subarray = []
        @subarray << @subject if !@subject.blank?
        @title = Worker.general_model_subs(@page.title,@subarray)
        @description = Worker.general_model_subs(@page.description, @subarray)
        render :action => @render_action
      else
        redirect_to '/', :status => 301
      end
    else
      redirect_to '/', :status => 301
    end
  end

  def school
    @no_top_monetize_show = true
    if !params[:url_string].blank? and @school = School.find_by_url_string(params[:url_string])

      @title = @school.name
      @title += ' :: ' + @school.city.name + ', ' + @school.state.two_letter_code rescue nil
      @title += ' :: Education Database Online'
      @description = @school.imported_mission_statement.gsub('"','')[0..500] if !@school.imported_mission_statement.blank?

    else
      redirect_to '/', :status => 301
    end

  end



  def contactsubmit

    if params[:anti] == '11' and !params[:message].blank?
      Notifier::deliver_message(['admin@onlineeducation.net'], ['bcarson@cmn.com'],'Message from OE Site',params[:message],false)
      flash[:notice] = 'Thank you!  Your message has been sent.'
      redirect_to '/contact', :status => 301
    else
      flash[:notice] = 'Please enter a message and answer the anti-spam question correctly.'
      redirect_to '/contact', :status => 301
    end

  end

  def needsredirect
    if params[:url_string].blank?
      redirect_to '/', :status => 301
    else
      redirect_to '/' + params[:url_string], :status => 301
    end
  end

  def switchboard
    @url_string = params[:url_string]
    @page_phrase = Worker.unurl(@url_string) if !@url_string.blank?

    if @page = Page.find_by_url_string(@url_string)
      @title = @page.title
      @description = @page.description
      @cousin = @page.cousin
      if !@page.cousin.blank?
        if @cousin != 'Schools'
          redirect_to '/schools/all/online', :status => 301
        else
          redirect_to '/schools/all/online', :status => 301
        end
      else
        case @url_string
          when 'higher-education'
            redirect_to '/schools/all/online', :status => 301
          when 'online-colleges-and-universities'
            redirect_to '/schools/all/online', :status => 301
          when 'reviews'
            #render :action => 'reviews'
            redirect_to '/schools/all/online', :status => 301
          else
            @no_top_monetize_show = true
            render :action => 'generic_page'
        end
      end

    else

      case @url_string

        when 'contact_us'
          redirect_to '/contact', :status => 301
        when 'contact-us'
          redirect_to '/contact', :status => 301
        when 'privacy'
          redirect_to '/privacy-policy', :status => 301
        when 'terms'
          redirect_to '/terms-and-conditions', :status => 301
        when 'sperm_quiz'
          redirect_to '/2009/11/17/how-much-is-your-sperm-worth', :status => 301
        when 'gay_quiz'
          redirect_to '/2009/11/17/how-long-could-you-survive-a-gay-bar-fight-armed-only-with-assless-chaps', :status => 301


        when /^online-.+?-degree-programs$/
          #is it an online-[DegreeLevel]-degree-programs?
          @result = @url_string.scan(/^online-(.+?)-degree-programs$/)
          if !@result.blank?

            #@potentialdegreelevel = Worker.unurl(@result[0][0])

            #if @degreelevel = Degreelevel.find(:first, :conditions => ['name = ?', @potentialdegreelevel])
            #  @page = Page.find_by_url_string('online-[DegreeLevel]-degree-programs')
            #  @title =  Worker.general_model_subs(@page.title, [@degreelevel])
            #  @description = Worker.general_model_subs(@page.description, [@degreelevel])
            #  @cousin = 'Degrees'

            #  render :action => 'degreelevel'
            #else
              #this is a page not found
             redirect_to '/', :status => 301
            #end


          end
        #end when online degreelevel degree in...


        when /^online-.+?-(degrees|programs|courses|classes|training|schools|colleges)$/
          #is it an online-[subject]-cousin?
          @result = @url_string.scan(/^online-(.+)-(.+?)$/)
          if !@result.blank?
            if @degreelevel = Degreelevel.find_by_name(@result[0][0])

              @programs = Program.find(:all, :limit => 100, :conditions => ['is_online = ? and inactive IS NULL AND degreelevels.id = ?', true, @degreelevel.id], :include => [:degreelevels])

              if @readyforthisguys == true and !@programs.blank?

                @page = Page.find_by_url_string('online-[DegreeLevel]-degree-in-[subject]')
                @title = Worker.general_model_subs(@page.title,[@degreelevel])
                @description = Worker.general_model_subs(@page.description, [@degreelevel])

                @cousin = 'Degrees'
                @degreespecial = true
                @schools = Worker.online_schools_from_online_programs(@programs)
                @online_schools = @schools
                @online_programs = @programs

                render :action => 'degreelevel'
                #render :text => 'asasd'
              else
                redirect_to '/', :status => 301
              end
            else
              @cousin_name_lowercase = @result[0][1]
              @cousin_name_lowercase = 'courses' if @cousin_name_lowercase == 'classes'
              @cousin_name_lowercase = 'programs' if @cousin_name_lowercase == 'training'
              @cousin_name_lowercase = 'programs' if @cousin_name_lowercase == 'degrees'
              @cousin_name_lowercase = 'schools' if @cousin_name_lowercase == 'colleges'

              redirect_to '/' + @cousin_name_lowercase + '/' +  @result[0][0] + '/online', :status => 301
            end
          end
        #end when online...


      when /^.+-certification$/
        #is it an subject certiication?
        @result = @url_string.scan(/^(.+)-certification$/)
        if !@result.blank?
          redirect_to '/certifications/' + @result[0][0], :status => 301
        end
      #end when online degreelevel degree in...


      when /^online-.+?-degree-in-.+$/
        #is it an online-[DegreeLevel]-degree-in-[subject]?
        @result = @url_string.scan(/^online-(.+?)-degree-in-(.+)$/)
        if !@result.blank?

          @potentialdegreelevel = Worker.unurl(@result[0][0])
          @potentialsubject = Worker.unurl(@result[0][1])

          if @degreelevel = Degreelevel.find(:first, :conditions => ['name = ?', @potentialdegreelevel]) and @subject = Subject.find(:first, :conditions => ['name = ? and prim = ?', @potentialsubject, true])

            #confirming we have a program that meets this degreelevel and subject
            #speed problems here -->
            @programs = Program.find(:all, :conditions => ['is_online = ? and inactive IS NULL AND degreelevels.id = ? and subjects.id = ?', true, @degreelevel.id, @subject.id], :include => [:degreelevels, :subjects])
            #@programs = Program.find(:all, :limit => 10, :conditions => ['is_online = ?', true])
            #@programs = Program.find(:all, :conditions => ['is_online = ? and degreelevels.id = ?', true, @degreelevel.id], :include => [:degreelevels])

            #@programs = Worker.get_degreelevel_from_programs(@degreelevel)
            #grab only the ones with the degreelevel in it

            #@new_p = []

            #for p in @programs
            #  @new_p << p if p.subjects.index(@subject)
            #end
            #@programs = @new_p



            if @readyforthisguys == true and !@programs.blank?

              #@programs = Worker.online_subject_programs(@subject)
              @schools = Worker.online_schools_from_online_programs(@programs)
              @online_schools = @schools
              @online_programs = @programs

              @page = Page.find_by_url_string('online-[DegreeLevel]-degree-in-[subject]')
              @title = Worker.general_model_subs(@page.title,[@subject, @degreelevel])
              @description = Worker.general_model_subs(@page.description, [@subject,@degreelevel])
              @schools = Worker.online_schools_from_online_programs(@programs)
              @online_schools = @schools
              @online_programs = @programs

              @cousin = 'Degrees'
              @degreespecial = true
              render :action => 'degreelevel_subject'

            else
              redirect_to '/online-' + Worker.inurl(@subject.name) + '-schools', :status => 301
            end
          else
            #this is a page not found
             redirect_to '/', :status => 301
          end
        end
      #end when online degreelevel degree in...





    when /^colleges-in-.+$/
      #is it an online-[DegreeLevel]-degree-programs?
      @result = @url_string.scan(/^colleges-in-(.+)$/)
      if !@result.blank?

        @potentialstate_or_city = Worker.unurl(@result[0][0])
        #@revised = true
        if @state = State.find(:first, :conditions => ['full_name = ?', @potentialstate_or_city])

          #@page = Page.find_by_url_string('colleges-in-[state]')
          #@title = Worker.general_model_subs(@page.title,[@state])
          #@description = Worker.general_model_subs(@page.description, [@state])

          #if @title.index(/Top 3/)
          #    @title.gsub!(/Top 3/, 'Top')
          #end

          #@cousin = 'Colleges'

          redirect_to '/schools/all/' + @state.two_letter_code

          #render :action => 'colleges_in_state'

        else

          if @city = City.find(:first, :conditions => ['name = ? and prim = ?', @potentialstate_or_city, true])
            @state = @city.state
            redirect_to '/schools/all/' + @state.two_letter_code + '/' + @result[0][0], :status => 301
          else
            #this is a page not found
            redirect_to '/', :status => 301
          end
        end
      end
  #end when online degreelevel degree in...


    when /^.+-schools-in-.+$/

      @result = @url_string.scan(/^(.+)-schools-in-(.+)$/)
      if !@result.blank?

        @potentialstate_or_city = Worker.unurl(@result[0][1])
        @state = State.find(:first, :conditions => ['full_name = ?', @potentialstate_or_city])
        @city = City.find(:first, :conditions => ['name = ?', @potentialstate_or_city]) if !@state
        @state = @city.state if @city and !@state

        if !@city and @state
          redirect_to '/schools/' + @result[0][0] + '/' + @state.two_letter_code, :status => 301
        else
          if @city
            redirect_to '/schools/' + @result[0][0] + '/' + @state.two_letter_code + '/' + @result[0][1], :status => 301
          else
            redirect_to '/', :status => 301
          end
        end #didn't match for some reason
      end

    #[Featuredschool]-reviews
    when /^.+-reviews$/
      redirect_to '/', :status => 301

      #something-questions
      when /^.+-questions$/

        @result = @url_string.scan(/^(.+)-questions$/)
        if !@result.blank?
          @revised = true
          @term = Worker.unurl(@result[0][0])

          @subject = Subject.find_by_name_and_prim(@term, true)
          @profession = Profession.find_by_name(@term) if @subject.blank?

          if !@subject.blank? || !@profession.blank?

            if !@subject.blank?
              redirect_to '/subjects/' + @result[0][0], :status => 301
            end

            if !@profession.blank?
              redirect_to '/professions/' + @result[0][0], :status => 301
            end

          else
              #this is a page not found
               redirect_to '/', :status => 301
          end
        end



      else #case @url_string

        #check if it is a subject or profession match
        if @subject = Subject.find_by_name(Worker.unurl(@url_string))
          redirect_to '/online-' + @url_string + '-schools', :status => 301
        else

          if @profession = Profession.find_by_name(Worker.unurl(@url_string))
            redirect_to '/online-' + Worker.inurl(@profession.subjects.first.name) + '-schools', :status => 301

          else

            redirect_to '/', :status => 301

          end
        end

        #if not then its a 404

      end #case @url_string

    end #else from if @page =
  end #def switchboard


  def generic_page

  end

  def faction

    @d = params[:d]
    @n = params[:n]
    @s = params[:s]
    @fid = params[:fid]
    @output = ''

    if @d and @fdeg = Fdeg.find_by_name(@d)

      @output = '<script type="text/javascript">'
      @output += 'document.myform' + @fid + '.node' + @fid + '.options.length=0;'
      @output += 'document.myform' + @fid + '.node' + @fid + '.options[0]=new Option("Select a Category","Select a Category",false,false);'
      @ct = 1
      for node in @fdeg.fcats
        @output += 'document.myform' + @fid + '.node' + @fid + '.options[' + @ct.to_s + ']=new Option("' + node.name + '","' + node.name + '",false,false);'
        @ct = @ct + 1
      end
        @output += 'document.myform' + @fid + '.node' + @fid + '.disabled = false;'
        @output += 'document.myform' + @fid + '.subject' + @fid + '.disabled = true;'

        @output += 'document.myform' + @fid + '.node' + @fid + '.focus();'

      @output += '</script>'
    end


    if @d and @n and @fdeg = Fdeg.find_by_name(@d) and @fcat = Fcat.find_by_name_and_fdeg_id(@n,@fdeg.id)

      @output = '<script type="text/javascript">'
      @output += 'document.myform' + @fid + '.subject' + @fid + '.options.length=0;'
      @output += 'document.myform' + @fid + '.subject' + @fid + '.options[0]=new Option("Select a Subject","Select a Subject",false,false);'

      @ct = 1
      for subject in @fcat.fsubs
        @output += 'document.myform' + @fid + '.subject' + @fid + '.options[' + @ct.to_s + ']=new Option("' + subject.name + '","' + subject.name + '",false,false);'
        @ct = @ct + 1
      end
        @output += 'document.myform' + @fid + '.subject' + @fid + '.disabled = false;'
        @output += 'document.myform' + @fid + '.subject' + @fid + '.focus();'

      @output += '</script>'
    end


    render :text => @output, :layout => false

  end


  def school_program_reviews

      #@featuredprogram = Featuredprogram.find(params[:id])
      #@url_string = params[:url_string]
      #@page_phrase = Worker.unurl(@url_string) if !@url_string.blank?

      #if !@featuredprogram.blank?
      #  @featuredschool = @featuredprogram.featuredschool
      #  @page = Page.find_by_url_string('[Featuredschool]-reviews-[Featuredprogram]')
      #  @title = Worker.general_model_subs(@page.title,[@featuredprogram])
      #  @description = Worker.general_model_subs(@page.description, [@featuredprogram])

      #  @cousin = 'Schools'
      #  @no_top_monetize_show = true

      #  render :action => 'featuredschool_review_featuredprogram'
      #else
          #this is a page not found
          #@output = @potentialprogram
      #end
      redirect_to '/', :status => 301

  end


  def livesearch

    @q = params[:q]
    if !@q.blank?

      @q = @q.gsub(/(<|>|\\|\/)/,'')


      @words = @q.split

      case @words.length
        when 1
          @programs = Qprogram.find(:all, :conditions => ['name like ?', "%" + @q + "%"], :limit => 4)
        when 2
          @programs = Qprogram.find(:all, :conditions => ['name like ? AND name like ?', "%" + @words[0] + "%", "%" + @words[1] + "%"], :limit => 4)
      else
        @programs = Qprogram.find(:all, :conditions => ['name like ? AND name like ? AND name like ?', "%" + @words[0] + "%", "%" + @words[1] + "%", "%" + @words[2] + "%"], :limit => 4)
      end

      @entries = []
      for p in @programs
        @in = []
        @in[0] = p.name
        @in[1] = p.schoolname
        @in[2] = '/getinfo/' + Worker.inurl(p.name) + '/program/' + p.pid.to_s + '/-/ls'

        @entries << @in
      end

      if @entries.blank?
        @schools = Featuredschool.find(:all, :conditions => ['name like ?', "%" + @q + "%"], :limit => 4)
        if !@schools.blank?
          for school in @schools
            @in = []
            @in[0] = school.name
            @in[1] = ''
            @in[2] = '/getinfo/' + Worker.inurl(school.name) + '/school/' + school.id.to_s + '/-/ls'
            @entries << @in
          end
        end
      end

      if @entries.blank?
        @subjects = Subject.find(:all, :conditions => ['name like ?', "%" + @q + "%"], :limit => 4)
        if !@subjects.blank?

          @ps = ['deg', 'tra', 'pro', 'cla', 'cou', 'cer', 'col', 'sch']
          for word in @words
            for p in @ps
              if word.index(/#{p}/)

                @cou = 'Degrees' if p == 'deg'
                @cou = 'Training' if p == 'tra'
                @cou = 'Programs' if p == 'pro'
                @cou = 'Classes' if p == 'cla'
                @cou = 'Courses' if p == 'cou'
                @cou = 'Colleges' if p == 'col'
                @cou = 'Schools' if p == 'sch'

              end
            end
          end

          @cou = 'Degrees' if @cou.blank?
          for sub in @subjects
            @in = []
            @in[0] = 'Online ' + sub.name + ' ' + @cou
            @in[1] = ''
            @in[2] = '/online-' + Worker.inurl(sub.name) + '-' + @cou.downcase
            @entries << @in
          end
        end

      end

      render :partial => 'livesearchtable', :layout => false
    else
      render :text => ''
    end
  end


  def update_map

    if params[:subject_id] != 'all'
      @schools = School.find(:all, :conditions => ['lat < ? and lat > ? and lng < ? and lng > ? and subjects.id = ?', params[:lat1], params[:lat2], params[:lng1], params[:lng2], params[:subject_id]], :order => 'rank DESC', :limit => 50, :include => [:subjects])
      @total_schools_count = School.count(:conditions => ['lat < ? and lat > ? and lng < ? and lng > ? and subjects.id = ?', params[:lat1], params[:lat2], params[:lng1], params[:lng2], params[:subject_id]], :include => [:subjects])

      @subject = Subject.find_by_id(params[:subject_id])
    else
      @schools = School.find(:all, :conditions => ['lat < ? and lat > ? and lng < ? and lng > ?', params[:lat1], params[:lat2], params[:lng1], params[:lng2]], :order => 'rank DESC', :limit => 50)
      @total_schools_count = School.count(:conditions => ['lat < ? and lat > ? and lng < ? and lng > ?', params[:lat1], params[:lat2], params[:lng1], params[:lng2]])
    end

    @show_housing = false
    @show_yelps = false

    if params[:show_yelps] == '1'

      @show_yelps = true
      @category = params[:yelp_category]
    end


    if params[:show_housing] == '1'

      @show_housing = true
      @hcategory = params[:housing_category]
    end






    render :partial => 'map_update', :layout => false
  end

  def load_school_info_view
    @school = School.find_by_id(params[:id])
    if @school
      render :partial => 'map_school_info_view', :layout => false
    else
      render :text => 'School not found - please try again later', :layout => false
    end
  end

  def load_courses
    @program = Program.find_by_id(params[:id])
    if @program
      render :partial => 'courses', :layout => false
    else
      render :text => ''
    end
  end

  def contact_message_go
    @school = School.find_by_id(params[:id])
    if @school and !params[:name].blank? and !params[:email].blank? and !params[:phone].blank? and !params[:body].blank?
      from = params[:name] + ' via OEDB <do-not-reply@onlineeducation.net>'
      #recipients = @school.name + ' Admissions <' + @school.admissions_office_email + '>'
      recipients = [@school.name + ' Admissions <' + @school.admissions_office_email + '>', params[:name] + ' <' + params[:email] + '>']
      subject = params[:name] + ' is requesting admissions information via onlineeducation.net'
      body = @school.name + ' Admissions,<br><br>'
      body += params[:name] + ' has sent you a message via http://www.onlineeducation.net/school/' + @school.url_string + '<hr><br>'
      body += '<b>Contact:</b> ' + params[:email] + ' - ' + params[:phone] + '<br><br>' rescue nil
      body += '<br><br><b>Message:</b><br><br>'
      body += params[:body]
      html = true
      Notifier::deliver_message(from,recipients,subject,body,html)
      render :text => 'Your message has been sent!'
    else
      render :text => 'Message not sent - school not identified - please try again later'
    end
  end

  def leave_comment_go
    @school = School.find_by_id(params[:id])
    if @school and !params[:body].blank?
      Comment.create(:name => params[:name], :body => params[:body], :ip => request.remote_ip, :school_id => @school.id)
      Notifier::deliver_message('admin@onlineeducation.net','wsfilter@gmail.com','new comment posted on newOE - ' + @school.name, params[:body],false)
      render :partial => 'comments'
    else
      render :text => 'No comment submitted - please refresh the page and try again.'
    end
  end

  def leave_rating_go
    @school = School.find_by_id(params[:id])
    if @school and !params[:rating].blank? and !Rating.find_by_ip(request.remote_ip)
      Rating.create(:num => params[:rating], :ip => request.remote_ip, :school_id => @school.id)
      render :text => '<br>Thank you. Your rating has been submitted.'
    else
      if @r = Rating.find_by_ip(request.remote_ip)
        @r.num = params[:rating]
        @r.save
        render :text => '<br>Your rating has been updated to ' + @r.num.to_s
      else
        render :text => '<br>No rating submitted - please refresh this page and try again.'
      end
    end
  end

  def matching_go

    if !params[:gpa].blank?

      @rlt = 200 if params[:gpa] == '3.8'
      @rlt = 90 if params[:gpa] == '3.5'
      @rlt = 70 if params[:gpa] == '3.0'
      @rlt = 50 if params[:gpa] == '2.5'
      @rlt = 40 if params[:gpa] == '2.0'
      @rlt = 30 if params[:gpa] == '0'

      case params[:size]
        when ['1','2']
          @size_text = ' AND student_population < 20000'
        when ['1']
          @size_text = ' AND student_population < 10000'
        when ['2','3']
          @size_text = ' AND student_population > 10000'
        when ['3']
          @size_text = ' AND student_population > 20000'
        when ['1','3']
          @size_text = ' AND (student_population > 20000 OR student_population < 10000)'
        when ['2']
          @size_text = ' AND (student_population > 10000 AND student_population < 20000)'
        else
          @size_text = ''
      end

      if params[:subject_id] == 'all'
        @subject_text = ''
        @theinclude = []
      else
        @theinclude = [:subjects]
        @subject_text = ' AND subjects.id = ' + params[:subject_id].gsub(/\D/,'')
      end


      case params[:location]
        when 'online'
          @schools = School.find(:all, :order => 'schools.priority DESC', :limit => 10, :conditions => ['is_online = 1' + @subject_text], :include => @theinclude)
        when 'anywhere'
          @schools = School.find(:all, :order => 'rank DESC', :limit => 10, :conditions => ['rank < ' + @rlt.to_s + @size_text + @subject_text], :include => @theinclude)
        when 'westcoast'
          @state_text = ' AND (state_id = 56 OR state_id = 6 OR state_id = 43)'
        when 'eastcoast'
          @state_text = ' AND (state_id = 23 OR state_id = 53 OR state_id = 34 OR state_id = 26 OR state_id = 8 OR state_id = 9 OR state_id = 37 OR state_id = 10 OR state_id = 47 OR state_id = 25 OR state_id = 55 OR state_id = 38 OR state_id = 48 OR state_id = 13 OR state_id = 12)'
        else
          @state_text = ' AND state_id = ' + params[:location].gsub(/\D/,'')
      end

      if @schools.blank?
        @schools = School.find(:all, :order => 'rank DESC', :limit => 10, :conditions => ['rank < ' + @rlt.to_s + @size_text + @subject_text + @state_text], :include => @theinclude)
      end

      render :partial => 'matching'
    else
      redirect_to '/'
    end
  end

  def load_yelp_listings


        #@school = School.find_by_id(params[:id])
        #if @school
        #  if @school.is_online?
        #    render :text => "yelp_display.innerHTML = '<br><br><center>Yelp data not available for online schools.<br><br>';"
        #  else
         @show_yelps = false
            #here is where we need to fetch the yelp API data - JSON object
            url = 'http://api.yelp.com/business_review_search?'
            url += 'tl_lat=' + params[:nw_lat]
            url += '&tl_long=' + params[:nw_lng]
            url += '&br_lat=' + params[:se_lat]
            url += '&br_long=' + params[:se_lng]
            #url += '&lat=' + @school.lat.to_s
            #url += '&long=' + @school.lng.to_s
            #url += '&radius=10'
            url += '&limit=20'
            params[:category].blank? ? @term = 'restaurants' : @term = params[:category]
            if @term != 'all'
              url += '&term=' + CGI::escape(@term)
            end
            @category = @term
            url += '&ywsid=8JpKYgc2fiD7zx2Yj4yRgg'

            @data = Worker.grab_page(url)
            #@data = ''
            @show_yelps = nil
            @show_yelps = true if params[:show_yelps] == '1'
            #render :text => 'yelp_display.innerHTML = "' + url + '";'
            render :partial => 'yelp_list', :layout => 'false'
        #  end
        #else
        #  render :text => 'Sorry, something went wrong - please try again later.'
        #end


  end

  def load_housing_listings
    if !params[:lat2].blank?
      @show_housing = false
      url = 'http://api.oodle.com/api/v2/listings?'
      url += 'key=2795C5BDCC0E'
      url += '&region=usa'
      url += '&location=' + params[:lat2] + '%2C' + params[:lng2] + '%2C' + params[:lat1] + '%2C' + params[:lng1]
      url += '&mappable=address'
      url += '&num=50'
      url += '&format=json'
      url += '&jsoncallback=none'
      params[:housing_category].blank? ? @hcategory = 'all' : @hcategory = params[:housing_category]
      if @hcategory != 'all'
        url += '&category=' + CGI::escape('housing/rent/' + @hcategory)
      else
        url += '&category=' + CGI::escape('housing/rent')
      end

      if @hcategory != 'all'
        url += '&category=' + CGI::escape('housing/rent/' + @hcategory)
      else
        url += '&category=' + CGI::escape('housing/rent')
      end

      atb = ''
      if !params[:baths].blank?
        atb += 'bathrooms_' + params[:baths] + '+,'
      end
      if !params[:beds].blank?
        atb += 'bedrooms_' + params[:beds] + '+,'
      end

      if !params[:price_min].blank? and !params[:price_max].blank?
       atb += 'price_' + params[:price_min] + '_' + params[:price_max] + ','
      else
        if !params[:price_min].blank?
          atb += 'price_' + params[:price_min] + '+,'
        end
        if !params[:price_max].blank?
          atb += 'price_' + params[:price_max] + '-,'
        end
      end

      if !params[:sqft_min].blank? and !params[:sqft_max].blank?
       atb += 'square_feet_' + params[:sqft_min] + '_' + params[:sqft_max] + ','
      else
        if !params[:sqft_min].blank?
          atb += 'square_feet_' + params[:sqft_min] + '+,'
        end
        if !params[:sqft_max].blank?
          atb += 'square_feet_' + params[:sqft_max] + '-,'
        end
      end

      url += '&attributes=' + CGI::escape(atb) if !atb.blank?


      #url += '&num_images=2'
      @housing_data = Worker.grab_page(url)
      #@housing_data = ''

      @show_housing = true if params[:show_housing] == '1'

      render :partial => 'housing_list', :layout => 'false'
      #render :text => @housing_data
    else
      redirect_to '/'
    end
  end

  def mapsearch

    @no_top_monetize_show = true

    if !params[:location].blank?
      @safeloc = params[:location].gsub(/(<|>|\?|;|)/,'')
      res=MultiGeocoder.geocode(@safeloc)
      if !res.blank? and !res.lat.blank? and !res.lng.blank?
        @origin = {}
        @origin['lat'] = res.lat
        @origin['lng'] = res.lng
        @map_on = true
        #@within = 100
        @within = 5 #if params[:l] == '10'
        @keepgoing = true
        @total_schools_count = 0
        while @total_schools_count == 0 and @keepgoing == true

          if !params[:subject].blank? and @subject = Subject.find_by_name(params[:subject])
            @schools = School.find(:all, :limit => 50, :origin =>[res.lat,res.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
          else
            @schools = School.find(:all, :limit => 50, :origin =>[res.lat,res.lng], :within=>@within, :order => 'rank DESC')
          end
          if !@schools.blank? and @schools.length > 1
            if !@subject.blank?
              @total_schools_count = School.count(:origin =>[res.lat,res.lng], :within=>@within, :order => 'rank DESC', :conditions => ['subjects.name = ?', @subject.name], :include => [:subjects])
            else
              @total_schools_count = School.count(:origin =>[res.lat,res.lng], :within=>@within, :order => 'rank DESC')
            end
          else

            case @within
              when 5
                @within = 10
              when 10
                @within = 50
              when 50
                @within = 100
              when 100
                @within = 500
              else
                if @within > 3000
                  @keepgoing = false
                else
                  @within += 500
                end
            end

          end
        end

        @title = 'Online Education Database Online Map Search for ' + @safeloc
        @description = 'Search for schools, housing, restaurants near ' + @safeloc

        @nearby_cities = City.find(:all, :conditions => ['prim = ?', true], :origin =>[@origin['lat'],@origin['lng']], :within=>100, :order => 'distance asc')
        @nearby_cities = @nearby_cities[0..30]
        @nearby_states = State.find(:all, :origin =>[@origin['lat'],@origin['lng']], :within=>1000, :order => 'distance asc')
        @nearby_states = @nearby_states[0..9]

        render :action => 'map_page'

      else
        redirect_to '/', :status => 301
      end
    else
      redirect_to '/', :status => 301
    end

  end

  def load_compare_results
    @schools = []
    for id in params[:ids].split(',')
      #little security here
      if id.index(/^\d+$/)
        @schools << School.find_by_id(id)
      end
    end

    @schools = @schools.sort{|a,b| b.rank <=> a.rank }

    render :partial => 'compare_results_content'
  end

  def poll_next_step

    @text_array = params[:txt]
    if @text_array.blank? || @text_array.length < 2 || params[:title].blank?
      render :text => '<br><br>Please ensure you have entered at least two schools and a poll title.'
    else
      #create the poll
      @p = Poll.new
      @p.title = params[:title]
      @p.ip = request.remote_ip
      @random_string = Worker.random_string
      @p.url_string = @random_string
      @p.url_string = Worker.random_string if Poll.find_by_url_string(@random_string)

      #grab bit.ly
      @d = Worker.grab_page('http://api.bitly.com/v3/shorten?apikey=R_ad82dbb97590c160ca59cf53aa7ab921&login=wecreatecontent&longUrl=' + CGI::escape('http://' + @thehost + '/poll/' + @p.url_string))
      @p.bitly_url = ActiveSupport::JSON.decode(@d)['data']['url'] rescue nil
      @p.save

      for item in @text_array
        if !item.blank?
          @p.pollitems << Pollitem.create(:name => item, :poll_id => @p.id)
        end
      end

      @p = Poll.last
      render :partial => 'poll_created', :layout => false

    end

  end

  def posted_on_facebook
    render :text => '<center><b>Your message has been posted on Facebook!</b></center>'
  end

  def poll_page

    if @poll = Poll.find_by_url_string(params[:url_string])

      @title = 'Custom Poll: ' + @poll.title
      @description = 'Take a quick poll to help a friend decide where to go (or apply) to school'
      @page_phrase = @title
      @no_top_monetize_show = true

      @pollvotes = @poll.pollvotes
      @pollitems = @poll.pollitems

    else
      redirect_to '/', :status => 301
    end
  end

  def vote_for_this

    if @pollitem = Pollitem.find_by_id(params[:id])

      if @pollvote = Pollvote.find_by_poll_id_and_ip(@pollitem.poll_id, request.remote_ip)

        if @pollitem.id == @pollvote.pollitem_id
          render :text => 'We have already recorded your vote for ' + @pollitem.name
        else
          @pollvote.pollitem_id = @pollitem.id
          @pollvote.save
          render :text => 'Your vote has been changed to: ' + @pollitem.name
        end

      else
        Pollvote.create(:poll_id => @pollitem.poll_id, :pollitem_id => @pollitem.id, :ip => request.remote_ip)
        render :text => 'Thank you. Your vote has been counted toward: ' + @pollitem.name
      end

    else
      render :text => 'Something went wrong - please try again later'
    end
  end

end
