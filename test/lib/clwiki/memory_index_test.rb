require_relative 'clwiki_test_helper'
require 'memory_index'

# rubocop:disable Metrics/AbcSize
class TestClWikiMemoryIndex < TestBase
  def test_with_same_mod_timestamp
    file_a = File.join(@temp_dir, 'TestFileA.txt')
    file_b = File.join(@temp_dir, 'TestFileB.txt')
    file_c = File.join(@temp_dir, 'TestFileC.txt')
    [file_a, file_b, file_c].each do |fn|
      FileUtils.makedirs(File.dirname(fn))
      File.open(fn, 'w+') { |f| f.puts 'sample file' }
    end
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
    file_a = File.join(@temp_dir, 'TestFileA.txt')
    file_b = File.join(@temp_dir, 'TestFileB.txt')
    file_c = File.join(@temp_dir, 'TestFileC.txt')
    terms = %w[foo bar qux thud]
    [file_a, file_b, file_c].each_with_index do |fn, idx|
      File.open(fn, 'w+') { |f| f.puts terms[idx..(idx + 1)] }
    end
    index = ClWiki::MemoryIndexer.new
    assert_equal %w[/TestFileB /TestFileC], index.search('qux').flatten
  end

  def test_page_exists
    file_a = File.join(@temp_dir, 'TestFileA.txt')
    [file_a].each_with_index do |fn, idx|
      File.open(fn, 'w+') { |f| f.puts 'test' }
    end
    index = ClWiki::MemoryIndexer.new
    assert index.page_exists?('/TestFileA')
    refute index.page_exists?('/TestFileB')
  end
end
# rubocop:enable Metrics/AbcSize
