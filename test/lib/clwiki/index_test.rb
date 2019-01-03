require File.dirname(__FILE__) + '/clwiki_test_helper'
require 'index'

class TestClWikiIndex < TestBase
  def test_indexing_files_with_same_mod_timestamp
    @temp_sub_dir = File.join(@temp_dir, 'SubPage')
    file_a = File.join(@temp_dir, 'TestFileA.txt')
    file_b = File.join(@temp_dir, 'TestFileB.txt')
    file_c = File.join(@temp_sub_dir, 'TestSubPageA.txt')
    [file_a, file_b, file_c].each do |fn|
      FileUtils.makedirs(File.dirname(fn))
      File.open(fn, 'w+') do |f| f.puts "sample file" end
    end
    # couldn't find a way to set the mtime quickly, so just trusting
    # the above code will run within the same second...
    assert_in_delta(File.mtime(file_a), File.mtime(file_b), 1.second)
    assert_in_delta(File.mtime(file_a), File.mtime(file_c), 1.second)
    @mtime = File.mtime(file_a)
    @i = ClWiki::Indexer.new
    $wiki_conf.access_log_index = false
    Dir.chdir(@temp_dir) do
      # puts .dat files into the tmp dir
      @i.build
    end
    recent = @i.recent
    assert_equal(1, recent.length)
    first = recent[0]
    assert_equal(2, first.length)
    assert_equal(@mtime.strftime("%Y-%m-%dT%H:%M:%S"), first[0])
    assert_equal(["/SubPage/TestSubPageA", '/TestFileB', '/TestFileA'], first[1])
  end
end
