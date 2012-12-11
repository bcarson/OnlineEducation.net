class FeedsController < ApplicationController
  
  def blog
    
    respond_to do |format|
      format.xml {
          @posts = Blog.find(:all, :limit => 10, :order => "created_at DESC")
      }

    end

  end

end