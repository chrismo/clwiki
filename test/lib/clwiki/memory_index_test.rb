# frozen_string_literal: true
require_relative 'clwiki_test_helper'

class MemoryIndexTest < TestBase
  def test_with_same_mod_timestamp
    file_a = create_legacy_file('TestFileA.txt')
    file_b = create_legacy_file('TestFileB.txt')
    file_c = create_legacy_file('TestFileC.txt')
    # couldn't find a way to set the mtime quickly, so just trusting
    # the above code will run within the same second...
    assert_in_delta(File.mtime(file_a), File.mtime(file_b), 1)
    assert_in_delta(File.mtime(file_a), File.mtime(file_c), 1)
    index = ClWiki::MemoryIndexer.new
    recent = index.recent
    assert_equal(%w[TestFileA TestFileB TestFileC], recent.sort)
  end

  def test_search
    terms = %w[foo bar qux thud]
    create_legacy_file('TestFileA.txt', terms[0..1])
    create_legacy_file('TestFileB.txt', terms[1..2])
    create_legacy_file('TestFileC.txt', terms[2..3])
    index = ClWiki::MemoryIndexer.new
    assert_equal %w[TestFileB TestFileC], index.search('qux').flatten
  end

  def test_search_titles_only
    terms = %w[foo bar qux thud]
    create_legacy_file('FooPage.txt', terms[0..1])
    create_legacy_file('BarPage.txt', terms[1..2])
    create_legacy_file('QuxPage.txt', terms[2..3])
    index = ClWiki::MemoryIndexer.new
    assert_equal %w[QuxPage], index.search('qu', titles_only: true)
    assert_equal %w[BarPage QuxPage], index.search('qu', titles_only: false)
  end

  def test_page_exists
    create_legacy_file('TestFileA.txt')
    index = ClWiki::MemoryIndexer.new
    assert index.page_exists?('TestFileA')
    refute index.page_exists?('TestFileB')
  end

  def test_reindex
    create_legacy_file('FileToReindex.txt', 'foo bar')
    index = ClWiki::MemoryIndexer.new
    file = ClWiki::File.new('FileToReindex', @test_wiki_path)
    file.content = 'bar qux'
    index.reindex_page('FileToReindex')
    assert_equal %w[FileToReindex], index.search('qux').flatten
  end

  def test_recent_with_search
    create_legacy_file('TestFileA.txt', 'foo')
    create_legacy_file('TestFileB.txt', 'bar')
    create_legacy_file('TestFileC.txt', 'qux')
    index = ClWiki::MemoryIndexer.new
    assert_equal %w[TestFileB], index.recent(3, text: 'bar')
  end
end
