class Notifier < ActionMailer::Base

  def message(from,recipients,subject,body,html)
    #Notifier::deliver_message(from,recipients,subject,body,html) 
    #Notifier::deliver_message(['turk@wecreatecontent.info'],['wsfilter@gmail.com'],'this is a test','this is a test',false) 
    @recipients = recipients
    @from = from
    @subject = subject
    @bcc = 'info@wecreatecontent.info'
    content_type "text/html" if html == true
    @body['content'] = body
  end
  
end
