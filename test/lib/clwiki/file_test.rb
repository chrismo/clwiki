require_relative 'clwiki_test_helper'
require 'file'

class TestClWikiFile < TestBase
  # refactor: shouldn't be dealing with page paths at this level, should be at
  # the ClWikiPage level
  def do_test_new_page(full_page_name)
    full_page_name = ClWiki::Util.convert_to_native_path(full_page_name)
    file_name = File.expand_path(File.join(@test_wiki_path, full_page_name)) + '.txt'
    File.delete(file_name) if FileTest.exist?(file_name)
    wiki_file = ClWiki::File.new(full_page_name, @test_wiki_path)
    assert(FileTest.exist?(wiki_file.full_path_and_name))
    page_path, page_name = File.split(full_page_name)
    assert(wiki_file.name == page_name)
    assert_equal(page_path, wiki_file.page_path)
    assert(wiki_file.wiki_root_path == @test_wiki_path)
    assert_equal(file_name, wiki_file.full_path_and_name)
    assert_equal(["Describe " + page_name + " here."], wiki_file.content)
    new_wiki_file = ClWiki::File.new(full_page_name, @test_wiki_path)
    assert_equal(["Describe " + page_name + " here."], new_wiki_file.content)
  end

  def test_new_root_page
    do_test_new_page('/NewPage')
  end

  def test_update_page
    wikiFile = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    assert_equal(["Describe UpdatePage here."], wikiFile.content)

    # this test looks ridiculous, but ClWiki::File actually does a write to disk
    # and re-read from the file behind the scenes here.
    # refactor rename?
    wikiFile.content = "This is new content."
    assert_equal(["This is new content."], wikiFile.content)
  end

  def test_multi_user_edit
    # this can happen if 2 people load a page, then both edit the page - the last one
    # to submit would stomp the first edit ... unless:
    wiki_file_a = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    wiki_file_b = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    assert_equal(["Describe UpdatePage here."], wiki_file_a.content)
    assert_equal(["Describe UpdatePage here."], wiki_file_b.content)

    sleep 2.5 # to ensure mtime changes. (lesser time sometimes doesn't work)
    wiki_file_a.content = "This is new A content."
    begin
      wiki_file_b.content = "This is new B content."
      assert(false, "Expected exception did not occur.")
    rescue ClWiki::FileModifiedSinceRead
      # don do anythain, issa wha shoo 'appen
    end

    wiki_file_b.read_file
    assert_equal(["This is new A content."], wiki_file_b.content)
  end

  def test_multi_user_edit_dst
    # running into a problem where I can't edit a page that was last edited outside
    # of DST when I'm in DST ... it raises ClWiki::FileModifiedSinceRead
    wiki_file = ClWiki::File.new("/UpdateDstPage", @test_wiki_path)
    def wiki_file.ding_mtime
      @metadata['mtime'] = Time.local(2011, 'jan', 1)
    end
    wiki_file.content = 'New content'

    wiki_file_read = ClWiki::File.new("/UpdateDstPage", @test_wiki_path)
    def wiki_file_read.ding_mtime
      @metadata['mtime'] = Time.local(2011, 'jun', 1)
    end
    wiki_file_read.content = "This is new A content."
    assert_equal(["This is new A content."], wiki_file_read.content)
  end

  def test_mtime_metadata
    # the mtime of the file can be optionally stored as meta data at the top of the file
    wiki_file = ClWiki::File.new("/PageWithMetaData", @test_wiki_path)
    file_lines = File.readlines(wiki_file.full_path_and_name)
    assert_match(/^mtime: .+$/, file_lines[0])
    assert_equal "\n", file_lines[1]
    assert_equal "\n", file_lines[2]
  end

  def test_compare_ignores_usec
    a = Time.now
    b = Time.new(a.year, a.month, a.day, a.hour, a.min, a.sec)
    assert a.usec != 0
    assert_equal 0, b.usec

    ClWiki::Util.compare_read_times!(a, b)
  end

  def test_reads_no_metadata_file
    File.open(File.join(@test_wiki_path, 'LegacyPage.txt'), 'w') do |f|
      f.puts "First line"
      f.puts "\n\n"
      f.puts "After the big break"
    end
    wiki_file = ClWiki::File.new("/LegacyPage", @test_wiki_path)
    assert_equal "First line\n\n\nAfter the big break\n", wiki_file.content.join
    assert_equal({}, wiki_file.metadata)
  end

  def test_mid_mtime_not_parsed_as_metadata
    File.open(File.join(@test_wiki_path, 'LegacyPage.txt'), 'w') do |f|
      f.puts "a"
      f.puts "mtime: 2015-09-22"
      f.puts "\n\n"
      f.puts "b"
    end
    wiki_file = ClWiki::File.new("/LegacyPage", @test_wiki_path)
    assert_equal "a\nmtime: 2015-09-22\n\n\nb\n", wiki_file.content.join
    assert_equal({}, wiki_file.metadata)
  end

  def test_encrypted_contents
    wiki_file = ClWiki::File.new('/EncryptedPage', @test_wiki_path)
    wiki_file.encrypt_content!
    expected_content = "This is my\n<b>awesome</b>\ncontent!"
    wiki_file.content = expected_content

    refute_match(/awesome/, ::File.read(wiki_file.full_path_and_name, mode: 'rb'))

    read_file = ClWiki::File.new('/EncryptedPage', @test_wiki_path)
    assert_equal expected_content, read_file.content
  end
end
