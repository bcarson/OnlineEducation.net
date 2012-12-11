class Admin::ProfessionsController < ApplicationController
  layout 'admin'
  

  def index
    page = params[:page] || 1
    @page = page
    if params[:name].blank?
      @professions = Profession.paginate :page => page, :per_page => 200, :order => 'name'
    else
      @professions = Profession.paginate :page => page, :per_page => 200, :order => 'name', :conditions => ['name like ?', "%" + params[:name] + "%"]      
    end
  end
  
  def update_prim_subject
    
    @profession = Profession.find(params[:id])
    if s = Subject.find_by_name(params[:subject_name])
      @profession.prim_subject_id = s.id
      @profession.save
      render :text => 'saved ' + Time.now.to_s
    else
      if params[:subject_name].blank?
        @profession.prim_subject_id = nil 
        @profession.save
        render :text => 'primary subject cleared'
      else
        render :text => params[:subject_name] + ' not found in our database, try again.'
      end
    end
    
  end
  
  
  def subject_suggest
    
    @id = params[:id]
    if params[:subject_name].length > 2
      
      @match = Subject.find(:first, :conditions => ['name = ? and prim = 1', params[:subject_name]])
      if !@match.blank?
        render :text => ''
      else

        @subjects = Subject.find(:all, :limit => 10, :conditions => ['name like ? and prim = 1', "%" + params[:subject_name] + "%"])      

        if @subjects.blank? 
          render :text => '<i>[no matching subject in db]</i>'
        else
          @output = '' 
          for subject in @subjects     
            @thesubmit = 'new Ajax.Updater(\'prim_submit_status' + @id.to_s + '\', \'/admin/professions/update_prim_subject?id=' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'form' + @id.to_s + '\'))});'                    
                    
            @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'entering_subject' + @id.to_s + '\').value=\'' + subject.name + '\';' + @thesubmit + '">' + subject.name + ' (as in ' + subject.opt_professions.first.name + ') </span><br>'  rescue nil
        	end
          render :text => @output          
        end
      end
    else
      render :text => ''
    end    
    
  end
  
end