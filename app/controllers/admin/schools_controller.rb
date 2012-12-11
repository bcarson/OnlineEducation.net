class Admin::SchoolsController < ApplicationController
  layout 'admin'
  
  skip_before_filter :verify_authenticity_token, :only => [:uploadnewpics, :update_onlineschoolpriority]
  
  
  def index
    #here we'd like to be able to take a params[:attr] and create a simple pagination UI to just edit that one field
    @attr = params[:attr].gsub(/[^\w_]/,'') unless params[:attr].blank? #just in case, make it clean
    @school_name = params[:school_name]
    params[:o] == 'rank' ? @o = 'rank DESC' : @o = 'name'
    page = params[:page] || 1
    if !@attr.blank? 
      
      case params[:attr] 
        when 'socialmedia'
          @special = true
          @schools = School.paginate :page => page, :per_page => 500, :order => @o, :select => 'id, name, city_id, website_url, facebook_url, twitter_username, blog_rss_url, blog_url, you_tube_url, linkedin_url'                  
        when 'newspapers'
          @special = true
          @schools = School.paginate :page => page, :per_page => 500, :order => @o, :select => 'id, name, city_id, website_url, campus_newspaper_name, campus_newspaper_url, local_newspaper_url, local_newspaper_name'                  
        when 'admissions'
          @special = true  
          @schools = School.paginate :page => page, :per_page => 500, :order => @o, :select => 'id, name, city_id, website_url, admissions_office_email,application_deadline,admissions_office_phone,admissions_office_address,admissions_transfer_url,admissions_requirements'  
      else
    
        if School.column_names.include? @attr            
          if !@school_name.blank? 
            @schools = School.paginate :page => page, :per_page => 500, :order => @o, :select => 'id, name, city_id, website_url, ' + @attr, :conditions => ['name like ?', "%" + @school_name + "%"]
            if !@schools.blank?

            else
              render :text => 'Sorry, "' + @school_name + '" not found'
            end              
          else
            @schools = School.paginate :page => page, :per_page => 500, :order => @o, :select => 'id, name, city_id, website_url, ' + @attr 
          end  
        else
          render :text => 'Sorry, you need to include a correct school attribute to edit.'
        end
      
      end #case
      

    else
      render :text => 'Sorry, you need to include a school attribute to edit.'
    end
    
    
  end
  
  def update_attr
    @school = School.find(params[:sid]) rescue nil
    unless @school.blank?
      @school.update_attributes(params[:school])
      render :text => 'saved ' + params[:school].inspect 
    else
      render :text => 'something went wrong', :layout => false
    end
  end
  
  def onlineschoolpriority
    
  end
  
  def update_onlineschoolpriority
    @school = School.find(params[:sid]) rescue nil
    unless @school.blank?
      @school.update_attributes(params[:school])
      render :partial => 'ospriorities'
    else
      render :text => 'something went wrong', :layout => false
    end      
  end

  def fzpicsreview
    
    page = params[:page] || 1
    @page = page
    if params[:name].blank?
      @schools = School.paginate :page => page, :per_page => 500, :order => 'rank DESC', :select => 'id, name, ipeds_id, full_address, website, city_id'
    else
      @schools = School.paginate :page => page, :per_page => 500, :order => 'rank DESC', :select => 'id, name, ipeds_id, full_address, website, city_id', :conditions => ['name like ?', "%" + params[:name] + "%"]      
    end
    
  end
  
  def uploadnewpics
    
    @logo = params[:logo]
    @photo = params[:photo]
    @school_id = params[:school_id]
    
    if (@logo || @photo) and @school = School.find(:first, :select => 'name, id, website, ipeds_id', :conditions => ['id = ?', @school_id])
      
      @dir = 'public/images/school/' + @school.picfoldernum + '/'
      FileUtils.mkdir_p(@dir) if !File.exists?(@dir)
      
      @logo_file = @dir + @logo.original_filename if @logo
      @photo_file = @dir + @photo.original_filename if @photo
      
      @bad = true if @logo and !@logo_file.index(/\.(gif|jpg|jpeg|png)$/)  
      @bad = true if @photo and !@photo_file.index(/\.(gif|jpg|jpeg|png)$/) 
      
      if !@bad     
        File.open(@logo_file, "wb") { |f| f.write(params['logo'].read) } if @logo
        File.open(@photo_file, "wb") { |f| f.write(params['photo'].read) } if @photo 

        if @logo
          `convert -trim #{@logo_file} #{@dir}logo.png` 
          `convert #{@dir}logo.png -resize 72x52 #{@dir}logo-small.png`
          `convert #{@dir}logo.png -resize 124x94 #{@dir}logo-med.png`
          `convert #{@dir}logo.png -resize 200x140 #{@dir}logo-large.png`          
        end
        if @photo
          `convert -trim #{@photo_file} #{@dir}photo.jpg` 
          `convert #{@dir}photo.jpg -resize 72x52 #{@dir}photo-small.jpg`
          `convert #{@dir}photo.jpg -resize 124x94 #{@dir}photo-med.jpg`         
          `convert #{@dir}photo.jpg -resize 200x140 #{@dir}photo-large.jpg`          
        end
                
        render :layout => false
          
      else
        render :text => 'Please ensure files uploaded are image files (gif, jpg, jpeg, or png)', :layout => false
      end

    else 
      render :text => 'Please ensure to upload a photo and/or a logo', :layout => false
    end
    
  
  end
  
  def rmatching
    page = params[:page] || 1
    @page = page
    if params[:name].blank?
      @crawlschools = Crawlschool.paginate :page => page, :per_page => 500, :order => 'name'
    else
      @crawlschools = Crawlschool.paginate :page => page, :per_page => 500, :order => 'name', :conditions => ['name like ?', "%" + params[:name] + "%"]      
    end    
  end
  
  
  def school_suggest
    @id = params[:cid]
    if params[:url_string].length > 2
      
      @match = School.find(:first, :conditions => ['url_string = ?', params[:url_string]])
      if !@match.blank?
        render :text => ''
      else

        @schools = School.find(:all, :limit => 10, :conditions => ['url_string like ?', "%" + params[:url_string].gsub(" ", "-") + "%"])      

        if @schools.blank? 
          render :text => '<i>[no matching school in db]</i>'
        else
          @output = '' 
          for school in @schools 
            @thesubmit = 'new Ajax.Updater(\'submit_status' + @id.to_s + '\', \'/admin/schools/update_crawlschool/' + @id.to_s + '\', {asynchronous:true, evalScripts:true, parameters:Form.serialize($(\'form' + @id.to_s + '\'))});'
        	  @output += '<span style="color: blue; cursor: pointer;" onClick="$(\'url_string' + @id.to_s + '\').value=\'' + school.url_string + '\'; ' + @thesubmit + '">' + school.url_string + ' (' + school.city.name + ', ' + school.state.two_letter_code + ')</span><br>'  rescue nil
        	end
          render :text => @output          
        end
      end
    else
      render :text => ''
    end
  end
  
  def update_crawlschool
    @crawlschool = Crawlschool.find_by_id(params[:id])
    if @crawlschool 
      c = School.find_by_url_string(params[:url_string])
      if c
       @crawlschool.school_id = c.id
       @crawlschool.save
       render :text => 'updated ' + Time.now.to_s + ' with ' + params[:url_string]
      else
        if params[:url_string].blank?
          @crawlschool.school_id = nil
          @crawlschool.save
          render :text => 'updated ' + Time.now.to_s + ' with NIL (cleared the school)'
        else
          render :text => 'could not find that school - sorry try again'
        end
      end
    else
       render :text => 'not updated - something went wrong - contact Will.'
    end
  end

end
