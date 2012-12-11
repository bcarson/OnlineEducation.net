class Admin::ProgramsController < ApplicationController
  layout 'admin'

  def index
    
  end

  def schoolprograms
    @school = School.find(params[:id]) rescue nil
    unless @school.blank?
      @programs = @school.programs.find(:all, :order => 'inactive', :conditions => ['is_online = 1'])
    else
      render :text => 'Sorry, could not find that school'
    end
    
  end
  
  def workonprogram
    @program = Program.find(params[:id]) rescue nil
    unless @program.blank?
      @courses = @program.courses
      @school = @program.school
    else
      render :text => 'could not find this program'
    end
    
  end
  
  def update_program
    @program = Program.find(params[:pid]) rescue nil
    unless @program.blank?
      @program.update_attributes(params[:program])
      render :text => 'Updated ' + Time.now.to_s
    else
      render :text => 'something went wrong', :layout => false
    end
  end
  
  def coursecheck  
    flash[:notice] = ''
    @program = Program.find_by_id(params[:id])
    if @program
      @replacement = Replacement.find_by_name_and_replaceable_id('school.courses', @program.id)
      if @replacement
        
        for num in (1..100)
          @name = nil
          @number = nil
          @course = nil
          @description = nil
          @credits = nil
          @name = @replacement.body['course' + num.to_s + 'name']
          @number = @replacement.body['course' + num.to_s + 'number']
          @description = @replacement.body['course' + num.to_s + 'description']
          @credits = @replacement.body['course' + num.to_s + 'credits']
          if !@name.blank? || !@number.blank?
          
            #does the course exist? 
            @course = Course.find(:first, :conditions => ['school_id = ? AND ((name != ? and name = ?) OR (number != ? and number = ?))', @program.school_id, '', @name, '', @number])
            if !@course.blank? 
              #does the course program join exist? 
              @cpj = Courseprogramjoin.find_by_program_id_and_course_id(@program.id, @course.id)
              if @cpj.blank? 
                #if not, make the join
                @cp = Courseprogramjoin.create(:program_id => @program.id, :course_id => @course.id)
                flash[:notice] += 'cpj' + @cp.id.to_s
              else
                flash[:notice] += 'already course and cpj - course ' + @course.id.to_s + ' CPJ - ' + @cpj.id.to_s + '<br>'
              end  
              
            else
              #make the course and make the join
              @course = Course.create(:school_id => @program.school_id, :name => @name, :number => @number, :description => @description, :credits => @credits)
              Courseprogramjoin.create(:program_id => @program.id, :course_id => @course.id)
              flash[:notice] += 's'
            end
          end
        end
         flash[:notice] += 'sd' if flash[:notice].blank?                 
      end
    end
    redirect_to '/admin/programs/workonprogram?id=' + params[:id]
  end
  
  def add_course
    @program = Program.find(params[:pid]) rescue nil
    unless @program.blank? 
      @course = Course.new(params[:course])
      @course.school_id = @program.school_id
      @course.save
      Courseprogramjoin.create(:program_id => @program.id, :course_id => @course.id, :is_optional => params[:is_optional])
      @courses = @program.courses
      render :partial => 'thecourselist'
    else
      render :text => 'uh oh'
    end
  end
  
  def update_course
    @course = Course.find(params[:cid]) rescue nil
    unless @course.blank?
      @course.update_attributes(params[:course])
      
      @courseprogramjoin = Courseprogramjoin.find(params[:cpjid]) rescue nil
      unless @courseprogramjoin.blank?
        @courseprogramjoin.update_attributes(params[:courseprogramjoin])
      end
      
      render :text => 'Updated ' + Time.now.to_s
    else
      render :text => 'something went wrong', :layout => false
    end
  end  

  def program_suggest
    if params[:name].length > 2
      
      @matchp = Program.find(:first, :conditions => ['is_online = 1 AND name = ? and school_id = ?', params[:name], params[:sid]])
      if !@matchp.blank?
        
        render :text => '<small>' + @matchp.zcourselist.gsub(/\n/,"<br>") + '</small>'
        
      else
        unless params[:m] == 'true'
          @program = Program.find(:first, :conditions => ['is_online = 1 AND school_id = ? AND name like ?', params[:sid], "%" + params[:name] + "%"])
        else
          @programs = Program.find(:all, :limit => 5, :conditions => ['is_online = 1 AND school_id = ? AND name like ?', params[:sid], "%" + params[:name] + "%"])      
        end
        if @programs.blank? and @program.blank? 
          render :text => '<i>[no program in db with this name]</i>'
        else
          @output = ''
          if @programs 
            for program in @programs 
          	  @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'pname\').value=\'' + program.name.gsub("'","") + '\';">' + program.name + '</span><br>' if !program.name.blank? 
          	end
            render :text => @output          
          
          else 
        	  @output += '<span onClick="$(\'pname\').value=\'' + @program.name.gsub(/'/,"\'") + '\'"></span><br>' if !@program.name.blank? 
            render :text => ' <i><small>There is a program named &raquo;</small></i> ' + @output
          end
        end
      end

    else
      render :text => ''
    end
  end

  def course_suggest
    if params[:name].length > 2
      unless params[:m] == 'true'
        @course = Course.find(:first, :conditions => ['school_id = ? AND name like ?', params[:sid], "%" + params[:name] + "%"])
      else
        @courses = Course.find(:all, :limit => 5, :conditions => ['school_id = ? AND name like ?', params[:sid], "%" + params[:name] + "%"])      
      end
      if @course.blank? and @courses.blank? 
        render :text => '<i>[no course in db with this name]</i>'
      else
        @output = ''
        if @courses 
          for course in @courses 
        	  @output += course.name if !course.name.blank? 
        	  @output += '|'
        	  @output += course.number if !course.number.blank? 
          	@output += '|'
          	@output += '|'
        	  @output += course.id.to_s 	
        	  @output += "<br>"
        	end
          render :text => '<small>' + @output + '</small>'          
          
        else 
      	  @output += @course.name if !@course.name.blank? 
      	  @output += '|'
      	  @output += @course.number if !@course.number.blank? 
        	@output += '|'
        	@output += '|'
      	  @output += @course.id.to_s 	
      	  @output += "\n"
          render :text => ' <i><small>There is a course named &raquo;</small></i> ' + @output
        end
      end
    else
      render :text => ''
    end
  end

  def courselist
    @program = Program.find(params[:id]) rescue nil
    unless @program.blank?
      @courses = @program.courses
      @school = @program.school
    else
      render :text => 'could not find this program'
    end   
  end

  def update_courselist
    @program = Program.find(params[:pid]) rescue nil
    unless @program.blank?
      if !params[:courselist].blank? 
        #destory current programjoins
        Courseprogramjoin.find_all_by_program_id(@program.id).each {|c| c.destroy}
        for line in params[:courselist].split("\n")
          if !line.blank? 
            @split = line.split("|")
            if @split and @split.length == 4
              @c = Courseprogramjoin.new
              @c.course_id = @split[3]
              @c.program_id = @program.id
              @c.is_optional = true if @split[2] == 'y' || @split[2] == 'Y' || @split[2] == '1' || @split[2] == 'yes' || @split[2] == 'Yes' 
              if !@c.course_id.blank? 
                @c.save 
              end
            end
          end
        end
        flash[:notice] = 'Saved ' + Time.now.to_s
        redirect_to '/admin/programs/courselist?id=' + @program.id.to_s 
      else
        render :text => 'something went wrong', :layout => false
      end
      
    else
      render :text => 'something went wrong', :layout => false
    end
  end


end