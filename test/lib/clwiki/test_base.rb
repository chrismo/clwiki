# frozen_string_literal: true

require 'fileutils'

require 'minitest'

require File.expand_path('clwiki_test_helper', __dir__)

require 'configuration'

class TestBase < MiniTest::Test
  def set_temp_dir
    @temp_dir = '/tmp/clwiki'
    @test_wiki_path = @temp_dir
    $wiki_path = @test_wiki_path
    $wiki_conf = ClWiki::Configuration.new
    $wiki_conf.wiki_path = $wiki_path
  end

  def setup
    set_temp_dir
    FileUtils::makedirs(@temp_dir)
  end

  def teardown
    FileUtils.remove_entry_secure(@temp_dir)
  end

  def create_legacy_file(filename, contents = 'contents')
    File.join(@temp_dir, filename).tap do |fn|
      File.open(fn, 'w+') { |f| f.puts contents }
    end
  end
end

