# frozen_string_literal: true

task reindex: :environment do
  indexer = ClWiki::IndexClient.new

  Dir[File.join($wiki_conf.wiki_path, "*#{$wikiPageExt}")].map do |fn|
    page_name = File.basename(fn, $wikiPageExt)
    indexer.reindex_page(page_name)
    print '.'
  end
end
