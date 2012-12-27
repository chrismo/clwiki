# Moves emails from a specific Thunderbird email folder into the Wiki
$LOAD_PATH << '..'
require 'clwiki'

Dir.chdir('..') # to allow default wiki conf file to be found

@wiki = ClWikiFactory.new_wiki

@folder_file = 'C:/Documents and Settings/Chris/Application Data/Thunderbird/Profiles/6i8ng1j7.default/Mail/pop3.clabs.org/Inbox.sbd/Wiki'
content = File.read(@folder_file)
emails = content.split(/^From - /)[1..-1]
emails.compact!
emails.each do |email|
  date = email.split(/\n/)[0]
  day, mon, date, time, year = date.split(' ')
  time.gsub!(/:/, '_')
  page_name = '/' + ['Email', year, mon, date, '', time].join('_')

  clientModTime = nil  # nil here will skip the check
  puts "writing #{page_name}..." 
  @wiki.updatePage(page_name, clientModTime, email)
end
# $wiki_conf.wait_on_threads
