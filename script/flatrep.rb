# frozen_string_literal: true

# read file - append to dest file with tags as first line
# dump output on dupes for review, but still just append

require 'fileutils'

root = __dir__
dest = "#{root}_flat"
FileUtils.makedirs(dest)

Dir[root + '/**/*.txt'].each do |pathfilename|
  dest_fn = File.join(dest, File.basename(pathfilename))
  tags = File.dirname(pathfilename.sub(root, '')).split('/')
  puts "Dupe: #{File.basename(pathfilename)}" if File.exists?(dest_fn)
  File.open(dest_fn, 'a') do |out|
    out.puts "\ntags: #{tags.join(' ')}"
    out.puts
    out.print File.read(pathfilename)
  end
end
