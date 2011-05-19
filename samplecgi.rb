#! f:/usr/local/bin/ruby

require "cgi"
require "find"
cgi = CGI.new("html4")  # add HTML generation methods
cgi.out {
  cgi.html {
    cgi.head { cgi.title{"TITLE"} } +
    cgi.body {
      cgi.pre {
        files = ""
        # Dir.foreach("c:\Temp") do |f|
        #   files = files + f + "\n"
        # end

        Find.find('c:\Temp') { |f| files = files + f + "\n" }

        files
      }
      cgi.pre() do
        CGI::escapeHTML(
          "params: " + cgi.params.inspect + "\n" +
          "cookies: " + cgi.cookies.inspect + "\n" +
          ENV.collect() do |key, value|
            key + " --> " + value + "\n"
          end.join("")
        )
      end
    }
  }
}

