# frozen_string_literal: true
if $PROGRAM_NAME == __FILE__
  $LOAD_PATH << '..'
  require 'clwikipage'
end

class FormatOPML < ClWiki::CustomFormatter
  def self.match_re
    %r{<opml.*?>.*?</opml>}m
  end

  def self.format_content(content, page)
    out = ['<NoWikiLinks>']
    content.grep(%r{<outline.*?>|</outline>}).each do |ln|
      title = ln.scan(/title=\"(.*?)\"/).compact
      html = ln.scan(/htmlUrl=\"(.*?)\"/).compact
      xml = ln.scan(/xmlUrl=\"(.*?)\"/).compact
      if html.empty? && xml.empty?
        if !title.empty?
          out << "<h4>#{title}</h4>"
          out << '<blockquote>'
        else
          out << '</blockquote>'
        end
      else
        out << "<a href='#{xml}'>[xml]</a> <a href='#{html}'>#{title}</a>"
      end
    end
    out.join("\n") + content
  end
end

ClWiki::CustomFormatters.instance.register(FormatOPML)

if $PROGRAM_NAME == __FILE__
  sample_opml = <<-OPMLTEXT
    <opml xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <head>
        <title>Generated by SharpReader - http://www.sharpreader.net</title>
      </head>
      <body>
        <outline type="rss" title="{ | one, step, back | }" description="Jim Weirich's Blog" xmlUrl="http://onestepback.org/index.cgi/index.rss" htmlUrl="http://onestepback.org/index.cgi" />
        <outline type="rss" title="A Few Comments (Bill Caputo)" description="" xmlUrl="http://www.williamcaputo.com/index.rdf" htmlUrl="http://www.williamcaputo.com/" />
        <outline type="rss" title="Allen Bauer's blog..." description="Borland Delphi and C#Builder IDE Architect.&#xA;Just jumping on the blogging bandwagon... oh look a cliff.." xmlUrl="http://homepages.borland.com/abauer/rss.xml" htmlUrl="http://homepages.borland.com/abauer" />
        <outline type="rss" title="Artima Weblogs" description="Artima Weblogs is a community of bloggers posting on a wide range of topics of interest to software developers." xmlUrl="http://www.artima.com/weblogs/feeds/weblogs.rss" htmlUrl="http://www.artima.com/weblogs/" />
        <outline type="rss" title="Bit Banger" description="The definitive source of everything Adam Keys." xmlUrl="http://www.trmk.org/~adam/blog/index.rdf" htmlUrl="http://trmk.org/~adam/blog/" />
        <outline type="rss" title="bt.etree.org" description="etree.org BitTorrent Tracker" xmlUrl="http://bt.etree.org/rss/bt_etree_org.rdf" htmlUrl="http://bt.etree.org/" />
        <outline type="rss" title="Cem Kaner's blog" description="Cem Kaner's weblog&#xA;Software testing, software safety, software law." xmlUrl="http://blackbox.cs.fit.edu/blog/kaner/index.rdf" htmlUrl="http://blackbox.cs.fit.edu/blog/kaner/" />
        <outline type="rss" title="ChadFowler.com" description="Chad Fowler's Random Posts on Computing, Language, and Travel" xmlUrl="http://www.chadfowler.com/?rss " htmlUrl="http://www.chadfowler.com/index.cgi" />
        <outline type="rss" title="cLabs Blogki" description="cLabs Blogki" xmlUrl="http://www.clabs.org/blogki/blogki.rss.cgi " htmlUrl="http://www.clabs.org/blogki" />
        <outline type="rss" title="Clay Shirky's Essays" description="Clay Shirky's Essays" xmlUrl="http://www.shirky.com/writings/rss.cgi" htmlUrl="http://www.shirky.com/writings/rss.cgi" />
        <outline type="rss" title="Collaborative Software Testing (Jonathan Kohl)" description="Jonathan Kohl's blog. Exploring tester and developer collaboration." xmlUrl="http://www.kohl.ca/blog/index.rdf" htmlUrl="http://www.kohl.ca/blog/" />
        <outline type="rss" title="Common Content: Newest Items" description="Common Content's latest posted items." xmlUrl="http://www.commoncontent.org/rss/newest.cgi" htmlUrl="http://www.commoncontent.org/" />
        <outline type="rss" title="Conversations with Dale" description="Dale H. Emery's Journal" xmlUrl="http://www.dhemery.com/journal/index.rdf " htmlUrl="http://www.dhemery.com/journal/" />
        <outline type="rss" title="Creative Commons: weblog" description="Creative Commons: weblog" xmlUrl="http://www.creativecommons.org/weblog/rss " htmlUrl="http://creativecommons.org/weblog/" />
        <outline type="rss" title="Dan Bricklin's Log" description="VisiCalc co-creator Dan Bricklin chronicles his life in the computer world with pictures, text, and commentary." xmlUrl="http://danbricklin.com/log_rss.xml" htmlUrl="http://danbricklin.com/log" />
        <outline type="rss" title="Don Box's Spoutlet" description="Rants from the SOAP box" xmlUrl="http://www.gotdotnet.com/team/dbox/rss.aspx" htmlUrl="http://www.gotdotnet.com/team/dbox/default.aspx" />
        <outline type="rss" title="Eric.Weblog()" description="Thoughts about software from yet another person who invented the Internet" xmlUrl="http://biztech.ericsink.com/rss.xml" htmlUrl="http://software.ericsink.com/" />
        <outline type="rss" title="Exploration Through Example (Brian Marick)" description="Exploration Through Example - Brian Marick" xmlUrl="http://www.testing.com/cgi-bin/blog/index.rss " htmlUrl="http://www.testing.com/cgi-bin/blog" />
        <outline title="Fluffy">
          <outline type="rss" title="/\ndy's Weblog" description="" xmlUrl="http://www.toolshed.com/blog/index.rss " htmlUrl="http://www.toolshed.com/blog" />
          <outline type="rss" title="Bill Dudney's Weblog" description="Bill Dudney's Weblog" xmlUrl="http://bill.dudney.net/roller/rss/bill" htmlUrl="http://bill.dudney.net/roller/page/bill" />
          <outline type="rss" title="Duncan's Blog" description="Personal website for James Duncan Davidson" xmlUrl="http://x180.net/Blog/index.rss " htmlUrl="http://x180.net" />
          <outline type="rss" title="Glenn Vanderburg: Weblog" description="Glenn Vanderburg's personal weblog." xmlUrl="http://www.vanderburg.org/cgi-bin/glv/blosxom?flav=rss " htmlUrl="http://www.vanderburg.org/cgi-bin/glv/blosxom" />
          <outline type="rss" title="Mike Clark" description="Mike's soapbox of life in the trenches" xmlUrl="http://www.clarkware.com/cgi/blosxom/index.rss" htmlUrl="http://www.clarkware.com/cgi/blosxom" />
          <outline type="rss" title="Ockham's Flashlight (Stuart Halloway)" description="Stuart Halloway on software development, technology, and the future." xmlUrl="http://www.relevancellc.com/halloway/weblog/rss.xml" htmlUrl="http://www.relevancellc.com/halloway/weblog/" />
          <outline type="rss" title="Potential Differences (Greg Vaughn)" description="Greg Vaughn on Java, Agile methodologies, OS X, whatever piques my interest!" xmlUrl="http://gigavolt.net/blog/index.rss" htmlUrl="http://gigavolt.net/blog" />
          <outline type="rss" title="PragDave" description="Dave's Weblog: Pragmatic Programming." xmlUrl="http://pragprog.com/pragdave/index.rss " htmlUrl="http://pragprog.com/pragdave" />
          <outline type="rss" title="Servlets.com Weblog (Jason Hunter)" description="Java, Open Source, XML, Web Services, and (gasp) .NET" xmlUrl="http://www.servlets.com/blog/index-all.xml" htmlUrl="http://www.servlets.com/blog/" />
        </outline>
        <outline type="rss" title="Joel on Software" description="Painless Software Management" xmlUrl="http://www.joelonsoftware.com/rss.xml " htmlUrl="http://www.joelonsoftware.com" />
        <outline type="rss" title="Luke Hutteman's Weblog" description="Luke Hutteman on Java, C#, J2EE, RSS and whatever else comes to mind..." xmlUrl="http://www.hutteman.com/weblog/rss.xml" htmlUrl="http://www.hutteman.com/weblog/" />
        <outline type="rss" title="Managing Product Development" description="Management, especially good management, is hard to do. This blog is for people who want to think about how they manage people, projects, and risk." xmlUrl="http://www.jrothman.com/weblog/RSS/mpdblogger_rss.xml" htmlUrl="http://www.jrothman.com/weblog/blogger.html" />
        <outline type="rss" title="Martin Fowler's Bliki" description="A cross between a blog and wiki of my partly-formed ideas on software development" xmlUrl="http://martinfowler.com/bliki/bliki.rss" htmlUrl="http://martinfowler.com/bliki" />
        <outline type="rss" title="mezzoblue" description="" xmlUrl="http://www.mezzoblue.com/rss/index.xml" htmlUrl="http://www.mezzoblue.com/" />
        <outline type="rss" title="Michael Feathers' Weblog" description="Let's Reconsider That" xmlUrl="http://www.artima.com/weblogs/feeds/bloggers/mfeathers.rss" htmlUrl="http://www.artima.com/weblogs/index.jsp?blogger=mfeathers" />
        <outline type="rss" title="OK/Cancel" description="OK/Cancel is a comic strip written for a very specific audience, but much of what we talk about is quite universal. Most everybody can relate to things in the world which don't work like they should. You needn't be a usability specialist, interaction designer, industrial designer or any sort of designer to appreciate that frustration. But if you ARE any of those aforementioned people or have had the pleasure and pain of working with one or more of this rare breed, this strip is for you." xmlUrl="http://www.ok-cancel.com/index.rdf" htmlUrl="http://www.ok-cancel.com/" />
        <outline type="rss" title="open.neurosaudio.com" description="" xmlUrl="http://open.neurosaudio.com/index.rdf" htmlUrl="http://open.neurosaudio.com/" />
        <outline title="Ruby">
          <outline type="rss" title="Ruby Application Archive" description="Summary for Ruby Application Archive, provided by Bulknews." xmlUrl="http://bulknews.net/rss/rdf.cgi?RAA" htmlUrl="http://www.ruby-lang.org/en/raa.html" />
          <outline type="rss" title="Ruby Garden Wiki" description="Recent Changes to the Ruby Garden" xmlUrl="http://www.rubygarden.com/rdf/cached/rubygarden-wiki.rdf" htmlUrl="http://www.rubygarden.org/ruby" />
          <outline type="rss" title="Ruby Weekly News" description="Recent news about Ruby" xmlUrl="http://www.rubygarden.com//rdf/cached/rurl.rdf" htmlUrl="http://www.rubygarden.org/rurl/html/index.html" />
          <outline type="rss" title="Ruby XML" description="" xmlUrl="http://www.rubyxml.com/rss0.91.xml" htmlUrl="" />
          <outline type="rss" title="ruby-doc" description="Recent postings to the Ruby Documentation Project web site." xmlUrl="http://www.ruby-doc.org/index.rb/rss0.91.xml" htmlUrl="http://www.ruby-doc.org/index.rb" />
        </outline>
        <outline type="rss" title="Ruminations" description="" xmlUrl="http://www.mcmains.net/ruminations/rss " htmlUrl="http://www.mcmains.net/ruminations" />
        <outline type="rss" title="SATN" description="Bob, David, and Dan's comments" xmlUrl="http://www.satn.org/satn_rss.xml" htmlUrl="http://www.satn.org" />
        <outline type="rss" title="Secure Programming News" description="News &amp; information related to secure programming topics" xmlUrl="http://www.secureprogramming.com/?action=rss&amp;feature=weblog" htmlUrl="http://www.secureprogramming.com/" />
        <outline type="rss" title="Secure Programming Recipes" description="Cookbook-style recipes for tackling programming problems securely." xmlUrl="http://www.secureprogramming.com/website.py?action=rss&amp;feature=recipes" htmlUrl="http://www.secureprogramming.com/?action=browse&amp;feature=recipes" />
        <outline type="rss" title="simplegeek (Chris Anderson - MS Architect)" description="" xmlUrl="http://www.simplegeek.com/blogxbrowsing.asmx/GetRss?" htmlUrl="http://www.simplegeek.com" />
        <outline type="rss" title="Slashdot" description="News for nerds, stuff that matters" xmlUrl="http://slashdot.org/slashdot.rss" htmlUrl="http://slashdot.org/" />
        <outline type="rss" title="Software (Management) Process Improvement" description="&quot;Poor management can increase software costs more rapidly than any other factor.&quot; (Barry Boehm)" xmlUrl="http://www.estherderby.com/weblog/RSS/blogger_rss.xml" htmlUrl="http://www.estherderby.com/weblog/blogger.html" />
        <outline type="rss" title="SourceForge.net: Project File Releases: Neuros Database Manipulator" description="SF.net File Releases: Neuros Database Manipulator (neurosdbm project) - Neuros Database Manipulator - Browse and modify the database of your Neuros Audio Computer.  Neuros Database Manipulator is written in Java for cross platform support." xmlUrl="http://sourceforge.net/export/rss2_projfiles.php?group_id=83367" htmlUrl="http://sourceforge.net/projects/neurosdbm/" />
        <outline type="rss" title="SQLServerCentral.Com - Articles" description="Articles posted on the SQLServercentral.com site." xmlUrl="http://www.sqlservercentral.com/sscrss.xml" htmlUrl="http://www.sqlservercentral.com" />
        <outline type="rss" title="Testing Hotlist Update" description="Bret Pettichord's Weblog. Observations of a Software Tester." xmlUrl="http://www.io.com/~wazmo/blog/index.rdf" htmlUrl="http://www.io.com/~wazmo/blog/" />
        <outline type="rss" title="The Idea Ether" description="Rich Kilmer's place to express the ideas that bounce around in his head." xmlUrl="http://richkilmer.blogs.com/ether/index.rdf" htmlUrl="http://richkilmer.blogs.com/ether/" />
        <outline type="rss" title="The Old New Thing" description="" xmlUrl="http://blogs.gotdotnet.com/raymondc/blogxbrowsing.asmx/GetRss?" htmlUrl="http://blogs.gotdotnet.com/raymondc/" />
        <outline type="rss" title="Thinking About Computing (Bruce Eckel)" description="Bruce Eckel's Web Log" xmlUrl="http://mindview.net/WebLog/RSS.xml" htmlUrl="http://www.MindView.net/WebLog/" />
        <outline type="rss" title="Ward Cunningham's Weblog" description="Ward Says, Don't Try This at Home" xmlUrl="http://www.artima.com/weblogs/feeds/bloggers/ward.rss " htmlUrl="http://www.artima.com/weblogs/index.jsp?blogger=ward" />
        <outline type="rss" title="Web Testing with Ruby" description="Web Testing with Ruby" xmlUrl="http://www.clabs.org/wtr/blogki.rss.cgi" htmlUrl="http://www.clabs.org//wtr/index.cgi" />
        <outline type="rss" title="whytheluckystiff.net" description="we've all got our ways of dealing with it." xmlUrl="http://whytheluckystiff.net/why.xml" htmlUrl="http://www.whytheluckystiff.net/" />
      </body>
    </opml>
  OPMLTEXT
  puts FormatOPML.format_content(sample_opml, nil)
end
