require 'clwikiindex'
require 'clwikitestbase'

class TestClWikiIndex < TestBase
  def test_indexing_files_with_same_mod_timestamp
    @tempSubDir = File.join(@tempDir, 'SubPage')
    file_a = File.join(@tempDir, 'TestFileA.txt')
    file_b = File.join(@tempDir, 'TestFileB.txt')
    file_c = File.join(@tempSubDir, 'TestSubPageA.txt')
    [file_a, file_b, file_c].each do |fn|
      File::makedirs(File.dirname(fn))
      File.open(fn, 'w+') do |f| f.puts "sample file" end
    end
    # couldn't find a way to set the mtime quickly, so just trusting
    # the above code will run within the same second...
    assert_equal(File.mtime(file_a), File.mtime(file_b))
    assert_equal(File.mtime(file_a), File.mtime(file_c))
    @mtime = File.mtime(file_a)
    @i = ClWikiIndexer.new
    $wikiConf.access_log_index = false
    Dir.chdir(@tempDir) do
      # puts .dat files into the tmp dir
      @i.build
    end
    recent = @i.recent
    assert_equal(1, recent.length)
    first = recent[0]
    assert_equal(2, first.length)
    assert_equal(@mtime, first[0])
    assert_equal(['/TestFileA', '/TestFileB', "/SubPage/TestSubPageA"], first[1])
  end
end
