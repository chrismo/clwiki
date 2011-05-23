# $Id: findinfiletest.rb,v 1.9 2005/05/30 19:27:51 chrismo Exp $
=begin
--------------------------------------------------------------------------
Copyright (c) 2001-2005, Chris Morris
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the names Chris Morris, cLabs nor the names of contributors to this
software may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
(based on BSD Open Source License)
=end

require 'findinfile'
require 'rubygems'
gem 'clutil'
require 'cl/util/test'
require 'test/unit'
require 'ftools'

class TestFindInFile < TempDirTest
  def set_temp_dir
    @temp_dir = '/tmp/clwiki'
    @test_wiki_path = @temp_dir
  end

  def setup
    super
    @find_path = @test_wiki_path
    @find_in_file = FindInFile.new(@find_path)
  end
  
  def create_test_file(filename, content)
    File.open(filename, 'w') do |f|
      f.puts(content)
    end
  end

  def test_initialization
    assert_equal(@find_path, @find_in_file.find_path)
  end

  def test_simple_find_content
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    assert_equal(1, @find_in_file.find('only'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def test_simple_find_filename
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    assert_equal(1, @find_in_file.find('tA'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def test_simple_find_content_case_insensitive
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    assert_equal(1, @find_in_file.find('oNly'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def test_simple_find_filename_case_insensitive
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    assert_equal(1, @find_in_file.find('Ta'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def test_match_in_file_name_and_content
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    assert_equal(1, @find_in_file.find('test'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def test_subdir_search
    File.makedirs(@test_wiki_path + '/subdir')
    create_test_file(@test_wiki_path + '/TestA.txt', 'this is only a test')
    assert_equal(1, @find_in_file.find('test'))
  end

  def test_title_only_search
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    create_test_file(@test_wiki_path + '/blah', 'this is only a test')
    assert_equal(1, @find_in_file.find('test', FindInFile::FILE_NAME_ONLY))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('TestA', @find_in_file.files[0])
  end

  def xtest_mini_load_test
    create_test_file(@test_wiki_path + '/TestA', 'this is only a test')
    content = ''
    1000.times do
      content << 'this is a sample file'
    end
    100.times do |x|
      create_test_file(@test_wiki_path + '/Test' + x.to_s, content)
    end
    start = Time.now
    assert_equal(1, @find_in_file.find('only'))
    stop = Time.now
    puts "find one file in 101"
    puts stop - start

    start = Time.now
    assert_equal(100, @find_in_file.find('sample'))
    stop = Time.now
    puts "find 100 file in 101"
    print stop - start
  end

  def test_recursive
    subdir = File.join(@test_wiki_path, '/subdir')
    File.makedirs(subdir)
    create_test_file(File.join(subdir, '/TestA.txt'), 'this is only a test')
    assert_equal(1, @find_in_file.find('Ta'))
    assert_equal(1, @find_in_file.files.length)
    assert_equal('subdir/TestA.txt', @find_in_file.files[0])
  end
end