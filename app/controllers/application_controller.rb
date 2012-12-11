# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotification::Notifiable
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :httpauth
  
  def httpauth

    

    if request.request_uri.index(/\/admin\//)
      unless request.env['HTTP_HOST'] == 'localhost:3000'
        authenticate_or_request_with_http_basic do |user_name, password|
          user_name == 'worker' && password == '8uGs82eL'
        end
      end
    else
      
      if request.env['HTTP_X_FORWARDED_HOST'] == 'www.onlineeducation.net' || request.env['HTTP_HOST'] == 'www.onlineeducation.net' || request.env['HTTP_HOST'] == '173.203.197.173' || request.env['HTTP_X_FORWARDED_HOST'] == '173.203.197.173'
        @thehost = 'www.onlineeducation.net'
        @fb_app_id = '156010531120486' #onlineeducation.net key        
      else
        if (request.env['HTTP_HOST'] and request.env['HTTP_HOST'].index(/assets/)) || (request.env['HTTP_X_FORWARDED_HOST'] and request.env['HTTP_X_FORWARDED_HOST'].index(/assets/))
        
          redirect_to 'http://www.onlineeducation.net' + request.env['REQUEST_URI'], :status => 301
        
        else  
          unless request.env['HTTP_HOST'] == 'localhost:3000'
            authenticate_or_request_with_http_basic do |user_name, password|
              user_name == 'preview' && password == 'newoedancing'   
            end
            
            if request.env['HTTP_X_FORWARDED_HOST'] == 'staging.onlineeducation.net' || request.env['HTTP_HOST'] == 'staging.onlineeducation.net'
              @thehost = 'staging.onlineeducation.net'
              @fb_app_id = '199276246763756' #staging.onlineeducation.net key              
            else            
              @thehost = 'newstaging.wecreatecontent.info'
              @fb_app_id = '187896314581839' #newstaging.wecreatecontent.info key
            end
          else
            @thehost = 'localhost:3000'
            @fb_app_id = '144198462310488' #LOCALHOST key
          end        
        end
      end
    end
  end  
  
end
