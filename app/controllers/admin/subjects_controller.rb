class Admin::SubjectsController < ApplicationController
  layout 'admin'
  

  def index
    page = params[:page] || 1
    @page = page
    if params[:name].blank?
      @subjects = Subject.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['prim = 1']
    else
      @subjects = Subject.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['prim = 1 AND name like ?', "%" + params[:name] + "%"]      
    end
  end

  
  def onlineprograms
    page = params[:page] || 1
    @page = page
    if params[:name].blank?
      @subjects = Subject.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['prim = 1']
    else
      @subjects = Subject.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['prim = 1 AND name like ?', "%" + params[:name] + "%"]      
    end
  end
  
  
  
  def update_prim_profession
    
    @subject = Subject.find(params[:id])
    if p = Profession.find_by_name(params[:profession_name])
      @subject.prim_profession_id = p.id
      @subject.save
      render :text => 'saved ' + Time.now.to_s
    else
      render :text => params[:profession_name] + ' not found in our database, try again.'
    end
    
  end
  
  def update_prim_zocc
    
    if @profession = Profession.find_by_id(params[:pid]) 
      if z = Zoccupation.find_by_name(params[:zocc_name])
        @profession.prim_zocc_id = z.id
        @profession.save
        render :text => 'saved ' + Time.now.to_s
      else
        render :text => params[:zocc_name] + ' not found in our database, try again.'
      end
    else
      render :text => 'Please first assign a profession - then try again'
    end
  end  
  
  
  def program_suggest
    
    @id = params[:id]
    if params[:program_name].length > 2
      
      @match = Program.find(:first, :conditions => ['name = ? and is_online = 1', params[:program_name]])
      if !@match.blank?
        render :text => ''
      else

        @programs = Program.find(:all, :limit => 10, :conditions => ['is_online = 1 AND inactive IS NULL and name like ?', "%" + params[:program_name] + "%"])      

        if @programs.blank? 
          render :text => '<i>[no matching program in db]</i>'
        else
          @output = '' 
          for program in @programs     
              @thesubmit = 'new Ajax.Updater(\'oplist' + @id.to_s + '\', \'/admin/subjects/add_program?id=' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'form' + @id.to_s + '\'))});'        
              @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_program' + @id.to_s + '\').value=\'' + program.name + '\';$(\'entering_zocc' + @id.to_s + '\').value=\'' + program.name + '\';$(\'pid' + @id.to_s + '\').value=\'' + program.id.to_s + '\';' + @thesubmit + '$(\'plist' + @id.to_s + '\').innerHTML = \'<i>refresh page to see list</i>\';">' + program.name + '</span><br>'  rescue nil
        	end
          render :text => @output          
        end
      end
    else
      render :text => ''
    end    
    
  end
  
  
  def profession_suggest
    
    @id = params[:id]
    if params[:profession_name].length > 2
      
      @match = Profession.find(:first, :conditions => ['name = ?', params[:profession_name]])
      if !@match.blank?
        render :text => ''
      else

        @professions = Profession.find(:all, :limit => 10, :conditions => ['name like ?', "%" + params[:profession_name] + "%"])      

        if @professions.blank? 
          render :text => '<i>[no matching profession in db]</i>'
        else
          @output = '' 
          for profession in @professions     
            if params[:adding] == '1'
              @thesubmit = 'new Ajax.Updater(\'plist' + @id.to_s + '\', \'/admin/subjects/add_p?sid=' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'add_p_form' + @id.to_s + '\'))});'        
              @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_add_profession' + @id.to_s + '\').value=\'' + profession.name + '\';' + @thesubmit + '$(\'entering_add_profession' + @id.to_s + '\').value=\'\';">' + profession.name + '</span><br>'  rescue nil              
            else
              @thesubmit = 'new Ajax.Updater(\'prim_submit_status' + @id.to_s + '\', \'/admin/subjects/update_prim_profession?id=' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'form' + @id.to_s + '\'))});'        
              @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_profession' + @id.to_s + '\').value=\'' + profession.name + '\';$(\'entering_zocc' + @id.to_s + '\').value=\'' + profession.name + '\';$(\'pid' + @id.to_s + '\').value=\'' + profession.id.to_s + '\';' + @thesubmit + '$(\'plist' + @id.to_s + '\').innerHTML = \'<i>refresh page to see list</i>\';">' + profession.name + '</span><br>'  rescue nil
            end
            #@output += profession.name + ' '
        	end
          render :text => @output          
        end
      end
    else
      render :text => ''
    end    
    
  end
  
  def zocc_suggest
    
    @id = params[:id]
    if params[:zocc_name].length > 2
      
      @match = Zoccupation.find(:first, :conditions => ['name = ?', params[:zocc_name]])
      if !@match.blank?
        render :text => ''
      else

        @zoccupations = Zoccupation.find(:all, :limit => 10, :conditions => ['name like ?', "%" + params[:zocc_name] + "%"])      

        if @zoccupations.blank? 
          render :text => '<i>[no matching zoccupation in db]</i>'
        else
          @output = '' 
          for zoccupation in @zoccupations     
            if params[:adding] == '1'
              @thesubmit = 'new Ajax.Updater(\'zlist' + @id.to_s + '\', \'/admin/subjects/add_z?sid=' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'add_z_form' + @id.to_s + '\'))});'                    
              @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_add_zocc' + @id.to_s + '\').value=\'' + zoccupation.name + '\';' + @thesubmit + '$(\'entering_add_zocc' + @id.to_s + '\').value=\'\';">' + zoccupation.name + '</span><br>'  rescue nil            
            else
              @thesubmit = 'new Ajax.Updater(\'zocc_submit_status' + @id.to_s + '\', \'/admin/subjects/update_prim_zocc\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'zform' + @id.to_s + '\'))});'                    
              @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_zocc' + @id.to_s + '\').value=\'' + zoccupation.name + '\';' + @thesubmit + '$(\'zlist' + @id.to_s + '\').innerHTML = \'<i>refresh page to see list</i>\';">' + zoccupation.name + '</span><br>'  rescue nil
            end
        	end
          render :text => @output          
        end
      end
    else
      render :text => ''
    end    
    
  end  

  
  def lists

    page = params[:page] || 1
    @page = page
    
    case params[:model]
    
      when 'profession'
        if params[:name].blank?
          @professions = Profession.paginate :page => page, :per_page => 200, :order => 'name'
        else
          @professions = Profession.paginate :page => page, :per_page => 200, :order => 'name', :conditions => ['name like ?', "%" + params[:name] + "%"]      
        end    
        
      when 'city'
        if params[:name].blank?
          @cities = City.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['prim = 1']
        else
          @cities = City.paginate :page => page, :per_page => 50, :order => 'name', :conditions => ['name like ? and prim = 1', "%" + params[:name] + "%"]      
        end    
        
      when 'state'
        if params[:name].blank?
          @states = State.paginate :page => page, :per_page => 20, :order => 'full_name'
        else
          @states = State.paginate :page => page, :per_page => 20, :order => 'full_name', :conditions => ['full_name like ?', "%" + params[:name] + "%"]      
        end    
        
    else
      if params[:name].blank?
        @subjects = Subject.paginate :page => page, :per_page => 20, :order => 'name', :conditions => ['prim = 1']
      else
        @subjects = Subject.paginate :page => page, :per_page => 20, :order => 'name', :conditions => ['prim = 1 AND name like ?', "%" + params[:name] + "%"]      
      end    
    end
  end
  
  
  
  def freview_go
    
    @replacement = Replacement.find_by_name_and_replaceable_id(params[:name],params[:mid].to_i) if !params[:mid].blank? 
    @our_hittype = Hittype.find(@replacement.hittype_id) if !@replacement.blank? and !@replacement.hittype_id.blank?
    @our_hittype = Hittype.find(:last, :conditions => ['name = ?', params[:name]]) if @our_hittype.blank? 
    
    if @replacement.blank? 

      @replacement = Replacement.new
      @replacement.name = params[:name]
      @replacement.replaceable_id = params[:mid]
      @replacement.replaceable_type = 'subject' if params[:name].index(/subject/)
      @replacement.replaceable_type = 'profession' if params[:name].index(/profession/)
      @replacement.replaceable_type = 'city' if params[:name].index(/city/)
      @replacement.replaceable_type = 'state' if params[:name].index(/state/)  
      @replacement.sandbox = false
      @replacement.hittype_id = @our_hittype.id if @our_hittype
      
    end
    
    if @our_hittype.action_type == 'replacements_long' || @our_hittype.action_type == 'replacements_special'
      @replacement.body = params[:body]
    else
      @replacement.body = params[:entries]
    end
    
    @replacement.hittype_id = @our_hittype.id if @replacement.hittype_id.blank?
    
    @replacement.save
    
    render :text => '<input type="submit" value="Updated ' + Time.now.to_s + ' - Thank You">', :layout => false
    
  end
  
  def remove_p
    
    if @subject = Subject.find_by_id(params[:sid]) and @profession = Profession.find_by_id(params[:pid])
      @subject.professions.delete(@profession)
    end
    render :partial => 'p_list'
  end
 
  def add_p
    if @subject = Subject.find_by_id(params[:sid]) and @profession = Profession.find_by_name(params[:profession_name])
      @subject.professions << @profession if !@subject.professions.index(@profession)
    end
    render :partial => 'p_list'
  end
  
  def add_program
    @subject = Subject.find_by_id(params[:sid])
    if @subject and @program = Program.find_by_name_and_is_online(params[:zocc_name], true)
      @program.subjects << @subject if !@program.subjects.index(@subject)
      @program.school.subjects << @subject if !@program.school.subjects.index(@subject)
    end
    render :partial => 'onlineps'
  end
  
  
  def add_z
    @subject = Subject.find_by_id(params[:sid])
    if @subject and @profession = @subject.primaryprofession and @zocc = Zoccupation.find_by_name(params[:zocc_name])
      @profession.zoccupations << @zocc if !@profession.zoccupations.index(@zocc)
    end
    render :partial => 'z_list'
  end
  
  
  def remove_z
    @subject = Subject.find_by_id(params[:sid])
    if @subject and @profession = @subject.primaryprofession and @zocc = Zoccupation.find_by_id(params[:zid])
          @profession.zoccupations.delete(@zocc)
    end
    
    render :partial => 'z_list'
  end
  
  
end