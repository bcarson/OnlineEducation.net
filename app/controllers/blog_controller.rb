class BlogController < ApplicationController

  before_filter :setstuff
  
  caches_page :index
  
  def setstuff
    @no_top_monetize_show = true
  end

  def index 
    @title = 'Education Database Online Blog'
    @description = 'Facts and interesting information on a wide variety of topics.'
    
    @year = params[:year]
    @month = params[:month]
    @day = params[:day]
    
    if @year and @year.index(/\d\d\d\d/)
      @thelike = @year.to_s 
      if @month and @month.index(/\d\d/)
        @thelike += '-' + @month.to_s
        if @day and @day.index(/\d\d/)
          @thelike += '-' + @day.to_s
        end
      end
    end
    
    @tag = params[:tag]
    
    @url_string = params[:url_string]
    
    if @url_string.blank? 
      page = params[:page] || 1
      @blogs = Blog.paginate :page => page, :per_page => 5, :order => 'created_at DESC' if !@tag and !@thelike
      
      @blogs = Blog.paginate :page => page, :per_page => 5, :order => 'created_at DESC', :conditions => ['created_at like ?', @thelike + "%"] if @thelike and @url_string.blank?
      
      if @tag and @tag = Tag.find_by_name(@tag)
        @blogs = @tag.blogs  
        @title = @tag.name + ' Articles'
        @subtitle = 'Education Database Online Blog'
        @description = 'Information about ' + @tag.name + ' on the Education Database Online blog, where you can find interesting and useful information.'        
      end
      if @blogs.blank?
        redirect_to '/blog'
      end
    else
      @blog = Blog.find_by_url_string(@url_string)
      if !@blog.blank?   
        @blogs = [@blog] 
        @title = 'Education Database Online Blog'
        @description = @blog.description 
      else
        redirect_to '/'
      end
    end
    
  end
  
  def blogpost
    
  end
end