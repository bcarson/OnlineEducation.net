xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title("Online Education Blog")
    xml.link("http://www.onlineeducation.net/blog")
    xml.description("Information about online education and careeers")
    xml.language('en-us')
    for post in @posts
      xml.item do
        xml.title(post.title)
        xml.description(post.body)
        # rfc822
        xml.pubDate(post.created_at.rfc2822)
      xml.link("http://www.onlineeducation.net/blog")
      xml.guid("http://www.onlineeducation.net/blog")
      end
    end
  }
}
