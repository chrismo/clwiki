require_relative 'clwiki_test_helper'
require 'index'

class IndexTest < TestBase
  def test_indexing_files_with_same_mod_timestamp
    file_a = create_legacy_file('TestFileA.txt')
    file_b = create_legacy_file('TestFileB.txt')
    file_c = create_legacy_file('TestFileC.txt')
    # couldn't find a way to set the mtime quickly, so just trusting
    # the above code will run within the same second...
    assert_in_delta(File.mtime(file_a), File.mtime(file_b), 1)
    assert_in_delta(File.mtime(file_a), File.mtime(file_c), 1)
    @mtime = File.mtime(file_a)
    index = ClWiki::Indexer.new
    $wiki_conf.access_log_index = false
    Dir.chdir(@temp_dir) do
      # puts .dat files into the tmp dir
      index.build
    end
    recent = index.recent
    assert_equal(1, recent.length)
    first = recent[0]
    assert_equal(2, first.length)
    assert_equal(@mtime.strftime('%Y-%m-%dT%H:%M:%S'), first[0])
    assert_equal(%w(/TestFileA /TestFileB /TestFileC), first[1].sort)
  end
end
