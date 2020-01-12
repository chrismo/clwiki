require 'dot/dot'
require 'cl/util/console'
require 'clwikiindex'

=begin
g = DOT::DOTDigraph.new({'name' => 'test'})
e = DOT::DOTEdge.new({'from' => 'a', 'to' => 'b'})
g << e
puts g.to_s
=end

def show_help
  puts '-p [FullPageName]   Page name for root analysis'
  puts '-d                  Turn on debug output'
  puts '-r                  Root text to remove from node names'
  puts '-s                  Single page'
end

def do_dot(graph, filename)
  puts graph.to_s if $debug
  f = File.new(filename, File::CREAT|File::TRUNC|File::RDWR)
  begin
    f.puts graph.to_s
  ensure
    f.close
  end
  system("dot -Tjpg #{filename} 1>#{filename}.jpg")
end

$debug = if_switch('-d')
rootText = get_switch('-r')
@singlePage = if_switch('-s')
puts rootText if $debug
if if_switch('-h')
  show_help
else
  i = ClWikiIndexer.new
  i.load
  rootPage = get_switch('-p')
  scanPages = [rootPage]
  scanned = []
  params = {'name' => 'clWiki', 'rankdir' => 'LR'}
  params['size'] = '"7.5,10"' if @singlePage
  g = DOT::DOTDigraph.new(params)
  while !scanPages.empty?
    scanPage = scanPages.pop
    if !scanned.include?(scanPage)
      puts 'scanning ' + scanPage
      pages = i.pages_out(scanPage)
      pages.sort!
      pages.each do |page|
        if scanPage != page
          scanPages.push page
          if rootText
            scanPagef = scanPage.sub(rootText, '') 
            pagef = page.sub(rootText, '')
          else
            scanPagef = scanPage 
            pagef = page
          end
          g << DOT::DOTEdge.new({'from' => "\"#{scanPagef}\"", 'to' => "\"#{pagef}\""})
        end
      end
      scanned << scanPage
    end
  end
  do_dot(g, 'wiki.dot')
end

#     def pages_out(rootPage)
#      all = @index.all_terms(rootPage, WAIT)
#      #all.delete_if do |term|
#      #  term[0..0] != '/' || !ClWikiPage.page_exists?(term.dup)
#      #end
#      all.delete_if do |term|
#        (term[0..0] != '/') || (term == '/') || (term == '//')
#      end
#      all.delete_if do |term|
#        !ClWikiPage.page_exists?(term.dup)
#      end
#      all
#    end