# frozen_string_literal: true

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
  f = File.new(filename, File::CREAT | File::TRUNC | File::RDWR)
  begin
    f.puts graph.to_s
  ensure
    f.close
  end
  system("dot -Tjpg #{filename} 1>#{filename}.jpg")
end

$debug = if_switch('-d')
root_text = get_switch('-r')
@single_page = if_switch('-s')
puts root_text if $debug
if if_switch('-h')
  show_help
else
  i = ClWikiIndexer.new
  i.load
  root_page = get_switch('-p')
  scan_pages = [root_page]
  scanned = []
  params = {'name' => 'clWiki', 'rankdir' => 'LR'}
  params['size'] = '"7.5,10"' if @single_page
  g = DOT::DOTDigraph.new(params)
  until scan_pages.empty?
    scan_page = scan_pages.pop
    next if scanned.include?(scan_page)

    puts 'scanning ' + scan_page
    pages = i.pages_out(scan_page)
    pages.sort!
    pages.each do |page|
      next unless scan_page != page

      scan_pages.push page
      if root_text
        scan_pagef = scan_page.sub(root_text, '')
        pagef = page.sub(root_text, '')
      else
        scan_pagef = scan_page
        pagef = page
      end
      g << DOT::DOTEdge.new('from' => "\"#{scan_pagef}\"", 'to' => "\"#{pagef}\"")
    end
    scanned << scan_page
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
