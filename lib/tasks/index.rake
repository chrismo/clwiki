# frozen_string_literal: true

def pct_done(done, total)
  pct = ((done.to_f / total.to_f) * 100).to_i
  pct.to_s.rjust(3) + '%'
end

task reindex: :environment do
  indexer = ClWiki::IndexClient.new

  entries = Dir[File.join($wiki_path, "*#{$wikiPageExt}")]
  entries.each_with_index.map do |fn, idx|
    if idx.divmod(100)[1].zero?
      puts
      print "#{pct_done(idx, entries.length)}: "
    end

    page_name = File.basename(fn, $wikiPageExt)
    indexer.reindex_page(page_name)
    print '.'
  end
  puts
  puts '100%'

  indexer.save
end
