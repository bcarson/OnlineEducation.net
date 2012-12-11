class GetinfoController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:gotoprogram]

  def gotoprogram
    
    @fid = params[:formid]
    
    if !@fid.blank? and @subject = Subject.find_by_name(params['subject' + @fid]) and @degreelevel = Degreelevel.find_by_name(params['degreelevel' + @fid])  
      
      @theprogram = Program.find(:first, :conditions => ['programs.is_online = 1 AND degreelevels.name = ? AND subjects.name = ?', @degreelevel.name, @subject.name], :include => [:degreelevels, :subjects])
    
      #@programs.sort! {|a,b| a.school.priority <=> b.school.priority}
      
      #@theprogram = @programs.last
    
      #count the click
      @click = Click.new
      @click.ip = request.remote_ip if request
      @click.ref = request.env['HTTP_REFERER'] if request
      @click.counted = false
      @click.clickable_id = @theprogram.id
      params[:loc].blank? ? @click.loc = '123' : @click.loc = params[:loc]
      @click.clickable_type = params[:ct] if !params[:ct].blank?
      @click.save
      
      if !@theprogram.blank? and !@theprogram.monetize_url.blank?
        @thegourl = @theprogram.monetize_url
        @thegourl += '/source/widget' if params[:loc] == '123-t'
        if @thehost == 'www.onlineeducation.net' || @thehost == 'staging.onlineeducation.net'
          @thegourl = @thegourl.gsub('http://schools.collegedegrees.com', '/onlineschools')
        end
        
        redirect_to @thegourl
      else
        redirect_to '/'
      end
    else
      redirect_to '/'
    end
    
  end

  def index
    @model = params[:model]
    @id = params[:id]
    
    if !@model.blank? and !@id.blank? and (@model == 'school' || @model == 'program')
      if @model == 'program'  
        if @program = Program.find_by_id(@id)
          @url = @program.monetize_url
        else
          redirect_to '/'
        end
      else
        if @school = School.find_by_id(@id)
          @url = @school.monetize_url
        else
          redirect_to '/'
        end
      end
      
      #count the click
      @click = Click.new
      @click.ip = request.remote_ip if request
      @click.ref = request.env['HTTP_REFERER'] if request
      @click.counted = false
      @click.clickable_id = @id
      @click.loc = params[:loc] if !params[:loc].blank?
      @model == 'school' ? @click.clickable_type = 'school' : @click.clickable_type = 'program' 
      @click.save
      
      if !@url.blank?

        @thegourl = @url
        if @thehost == 'www.onlineeducation.net' || @thehost == 'staging.onlineeducation.net'
          @thegourl = @thegourl.gsub('http://schools.collegedegrees.com', '/onlineschools')
        end
        
        redirect_to @thegourl
        
      else
        redirect_to '/'
      end
    else
      redirect_to '/'  
    end
    
  end

end