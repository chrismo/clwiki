#!c:/ruby/bin/ruby.exe
require 'cl/util/win'
require 'cgi'

begin
  @cgi = CGI.new("html3")
  queryString = ENV['QUERY_STRING']
  queryHash = {}
  queryHash = CGI.parse(queryString) if queryString 
  dotfn = queryHash['fn']
  dotfn = 'test.dot' if !dotfn
  pngfn = Time.now.strftime("%Y%m%d%H%M%S") + Time.now.usec.to_s + '.png'
  
  print "Content-type: image/png\r\n\r\n"
  STDOUT.binmode
  system("graphviz\\dot.exe -Tpng -o #{File.winpath(pngfn)} #{dotfn}")
  File.open(pngfn, 'rb') do |f|
    print f.read
  end
  File.delete pngfn 
rescue Exception => e
  print "Content-type: text/html\r\n\r\n"
  puts e.message << "\n" << e.backtrace.join("\n")
end
