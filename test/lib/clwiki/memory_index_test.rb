require_relative 'clwiki_test_helper'
require 'memory_index'

# rubocop:disable Metrics/AbcSize
class MemoryIndexTest < TestBase
  def test_with_same_mod_timestamp
    file_a = create_legacy_file('TestFileA.txt')
    file_b = create_legacy_file('TestFileB.txt')
    file_c = create_legacy_file('TestFileC.txt')
    # couldn't find a way to set the mtime quickly, so just trusting
    # the above code will run within the same second...
    assert_in_delta(File.mtime(file_a), File.mtime(file_b), 1)
    assert_in_delta(File.mtime(file_a), File.mtime(file_c), 1)
    @mtime = File.mtime(file_a)
    index = ClWiki::MemoryIndexer.new
    recent = index.recent
    assert_equal(1, recent.length)
    first = recent[0]
    assert_equal(2, first.length)
    assert_equal(@mtime.strftime('%Y-%m-%dT%H:%M:%S'), first[0])
    assert_equal(%w[/TestFileA /TestFileB /TestFileC], first[1].sort)
  end

  def test_search
    terms = %w[foo bar qux thud]
    file_a = create_legacy_file('TestFileA.txt', terms[0..1])
    file_b = create_legacy_file('TestFileB.txt', terms[1..2])
    file_c = create_legacy_file('TestFileC.txt', terms[2..3])
    index = ClWiki::MemoryIndexer.new
    assert_equal %w[/TestFileB /TestFileC], index.search('qux').flatten
  end

  def test_page_exists
    create_legacy_file('TestFileA.txt')
    index = ClWiki::MemoryIndexer.new
    assert index.page_exists?('/TestFileA')
    refute index.page_exists?('/TestFileB')
  end
end
# rubocop:enable Metrics/AbcSize
