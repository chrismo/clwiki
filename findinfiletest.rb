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
require 'cl/util/test'
require 'test/unit'
require 'ftools'

class TestFindInFile < TempDirTest
  def setTempDir
    @tempDir = '/tmp/clwiki'
    @testWikiPath = @tempDir
  end

  def set_up
    super
    @findPath = @testWikiPath
    @findInFile = FindInFile.new(@findPath)
  end
  
  alias setup set_up

  def createTestFile(fileName, content)
    f = File.new(fileName, File::CREAT|File::RDWR|File::TRUNC)
    f.puts(content)
    f.flush
    f.close
  end

  def testInitialization
    assert_equal(@findPath, @findInFile.findPath)
  end

  def testSimpleFindContent
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    assert_equal(1, @findInFile.find('only'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def testSimpleFindFilename
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    assert_equal(1, @findInFile.find('tA'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def testSimpleFindContentCaseInsensitive
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    assert_equal(1, @findInFile.find('oNly'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def testSimpleFindFilenameCaseInsensitive
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    assert_equal(1, @findInFile.find('Ta'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def testMatchInFileNameAndContent
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    assert_equal(1, @findInFile.find('test'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def testSubdirSearch
    File.makedirs(@testWikiPath + '/subdir')
    createTestFile(@testWikiPath + '/TestA.txt', 'this is only a test')
    assert_equal(1, @findInFile.find('test'))
  end

  def testTitleOnlySearch
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    createTestFile(@testWikiPath + '/blah', 'this is only a test')
    assert_equal(1, @findInFile.find('test', FindInFile::FILE_NAME_ONLY))
    assert_equal(1, @findInFile.files.length)
    assert_equal('TestA', @findInFile.files[0])
  end

  def xtestMiniLoadTest
    createTestFile(@testWikiPath + '/TestA', 'this is only a test')
    content = ''
    1000.times do
      content << 'this is a sample file'
    end
    100.times do |x|
      createTestFile(@testWikiPath + '/Test' + x.to_s, content)
    end
    start = Time.now
    assert_equal(1, @findInFile.find('only'))
    stop = Time.now
    puts "find one file in 101"
    puts stop - start

    start = Time.now
    assert_equal(100, @findInFile.find('sample'))
    stop = Time.now
    puts "find 100 file in 101"
    print stop - start
  end

  def test_recursive
    subdir = File.join(@testWikiPath, '/subdir')
    File.makedirs(subdir)
    createTestFile(File.join(subdir, '/TestA.txt'), 'this is only a test')
    assert_equal(1, @findInFile.find('Ta'))
    assert_equal(1, @findInFile.files.length)
    assert_equal('subdir/TestA.txt', @findInFile.files[0])
  end
end