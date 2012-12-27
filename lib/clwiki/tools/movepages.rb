require 'ftools'

files = File.readlines('pagestomove.txt')
srcdir = 'W:/WikiRepository/fotwiki'
destdir = File.join(srcdir, 'DocuTIMEEmpACT', 'IncidentBase')
files.collect! do |fn| File.join(srcdir, fn.chomp!) + '.txt' end
files.each do |fn|
  File.copy fn, fn + '.bak'
  filecontent = File.readlines(fn)
  destfn = File.join(destdir, File.basename(fn))
  File.open(destfn, 'w+') do |fout|
    fout.puts filecontent
  end
  File.open(fn, 'w+') do |fout|
    fout.puts 'see //DocuTIMEEmpACT/IncidentBase/' + File.basename(fn, '.txt')
  end
  puts 'destfn: ' + destfn
end


# note: this works for easy moves - but with the hierarchy
# complications in terms of links inside the content, a good
# first move would be to convert to absolute paths in all
# wiki pages referenced in content of pages being moved.
# Then replace any links in moving content appropriately.

# see clwikipage.rb.convert_relative_wikinames_to_absolute