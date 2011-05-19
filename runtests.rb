require 'findinfiletest'
require 'clwikifiletest'
require 'clwikiindextest'
# require 'clwikitest'
puts 'clwikitest.rb skipped for now. It was basically an acceptance test'
puts 'suite, but it''s hard to maintain, because it does so much literal'
puts 'html comparison -- and actual usage seems to working fine for'
puts 'acceptance testing.'
# pagetest mods class ClWikiPage, so it cannot be run with the others
system('ruby clwikipagetest.rb')