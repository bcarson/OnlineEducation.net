module HomeHelper
  
  def url_ready(input)
    
    @i = input.strip
    @i = @i.gsub(/\s/,'-')
    @i.downcase
    
  end
  
  def sd(subject)
    subject.gsub(/\sand\s/, ' & ')
  end

  def subject_cousin_url(subject,cousin)
   '<a href="/online-' + url_ready(subject.name) + '-' + cousin + '">' + sd(subject.name) + '</a>'  
  end
  
  def show_more(output, cut_off_length)
    thereturn = ''
    uid = rand(2030430204).to_s

		if !output.blank? and output.split.size > cut_off_length 
	    thereturn = output.split[0..(cut_off_length-1)].join(" ") 
	    thereturn += ' <span id="show_more' + uid + '" class="show_more" onClick="$(\'#school_d' +  uid + '_more_content\').show();' 
	    thereturn += '$(this).hide();" id="school_d' + uid + '_more">...show more &raquo;</span><span style="display:none"' 
	    thereturn += 'id="school_d' + uid + '_more_content">' + output.split[cut_off_length..9999999].join(" ")
	    thereturn += ' <span onClick="$(\'#show_more' +  uid + '\').show(); $(\'#school_d' +  uid + '_more_content\').hide();" class="show_more"> &laquo;show less</span>'
	    thereturn +=  '</span>'
	    return thereturn 
	  else 
	    return output
	  end     
  end

  def show_more_to_school(output, cut_off_length, school)
    thereturn = ''
    uid = rand(2030430204).to_s

		if !output.blank? and output.split.size > cut_off_length 
	    thereturn = output.split[0..(cut_off_length-1)].join(" ") 
	    thereturn += '... <a href="/school/' + school.url_string + '">learn more &raquo;</a>'
	    return thereturn 
	  else 
	    return output
	  end     
  end
  
  
  # Styling Helpers
  # Wasn't sure the best place for this- feel free to move where this belongs.
  #
  
  # Add a class to the last entry
  def dom_class_last(object, array)
    if (object == array.last)
      return "last"
    end
    nil
  end
  
  # Get rid of widows
  def widont_single(text)
    text.strip!
    text[text.rindex(' '), 1] = '&nbsp;' if text.rindex(' ')
    text
  end
  
end
