# frozen_string_literal: true

task reindex: :environment do
  indexer = ClWiki::IndexClient.new

  entries = Dir[File.join($wiki_path, "*#{$wikiPageExt}")]
  entries.each_with_index.map do |fn, idx|
    if idx.divmod(100)[1].zero?
      puts
      print "#{idx.to_s.rjust(3)}%: "
    end

    page_name = File.basename(fn, $wikiPageExt)
    indexer.reindex_page(page_name)
    print '.'
  end

  indexer.save
end
