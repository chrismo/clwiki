# frozen_string_literal: true

def pct_done(done, total)
  pct = ((done.to_f / total.to_f) * 100).to_i
  pct.to_s.rjust(3) + '%'
end

desc 'Reindex the wiki pages.'
task reindex: :environment do
  indexer = ClWiki::MemoryIndexer.instance

  entries = Dir[File.join($wiki_conf.wiki_path, "*#{ClWiki::FILE_EXT}")]
  entries.each_with_index.map do |fn, idx|
    if idx.divmod(100)[1].zero?
      puts
      print "#{pct_done(idx, entries.length)}: "
    end

    page_name = File.basename(fn, ClWiki::FILE_EXT)
    indexer.reindex_page(page_name)
    print '.'
  end
  puts
  puts '100%'

  indexer.save
end
