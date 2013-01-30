xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "clWiki"
    xml.description "clWiki"
    xml.link root_url

    for page in @pages
      xml.item do
        xml.title page.name
        xml.description page.content
        xml.pubDate page.mtime.to_s(:rfc822)
        xml.link page_show_url(:page_name => page.name)
        xml.guid page_show_url(:page_name => page.name)
      end
    end
  end
end