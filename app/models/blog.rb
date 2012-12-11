class Blog < ActiveRecord::Base

  has_and_belongs_to_many :tags

  def is_infographic?
    
    self.tags.index(Tag.find_by_name('Infographic'))
    
  end
  
  def featured_pic_url
    if self.is_infographic?
  	  return "/images/infographics/large/" + self.url_string + ".jpg"
    else
	    return "/images/blogs/" + self.url_string + "/featured.jpg"
    end 
  end
  
  def url
    
    @out = '/' + self.created_at.strftime("%Y") + '/' + self.created_at.strftime("%m") + '/' + self.created_at.strftime("%d") + '/' + self.url_string
    
  end

end
