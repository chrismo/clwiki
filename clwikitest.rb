# $Id: clwikitest.rb,v 1.55 2005/05/30 19:27:51 chrismo Exp $
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

require 'clwiki'
require 'clwikitestbase'
require 'ftools'

class TestClWiki < TestBase
  def set_up
    super
    @clWiki = ClWiki.new(@testWikiPath)
    sleep 1
  end

  def doTestNewPageThruWiki(pageNameArray, separator)
    @clWiki = ClWiki.new(@testWikiPath)
    fullPageName = separator + pageNameArray.join(separator)
    fullPageName = ClWikiUtil.convertToNativePath(fullPageName)
    actualContent = @clWiki.displayPage(fullPageName).content

    pageName = pageNameArray.last
    assert_equal(buildExpectedContent(fullPageName), actualContent,
      'pageNameArray: ' + pageNameArray.inspect + ' separator: ' + separator)
  end

  def testNewPageThruWiki
    # this is getting tedious to keep up...
    # doTestNewPageThruWiki(['NewPage'], '/')
    # doTestNewPageThruWiki(['NewPage', 'NewSubPage'], "\\")
    # doTestNewPageThruWiki(['NewPage', 'NewSubPage'], '/')
    # doTestNewPageThruWiki(['NewSubPage'], "\\")
    # doTestNewPageThruWiki(['NewSubPage'], '/')
  end

  def testDisplayPage
    @clWiki = ClWiki.new(@testWikiPath)
    testPage = '/TestPage'
    wikiPageModTime = @clWiki.displayPage(testPage).modTime
    updateContent = "Sample text before\n\n" +
      "<table>\n<tr>\n<td>testdata</td>\n</tr>\n</table>\n" +
      "Sample text <a href='http://clabs.org'>after</a>\n"

    readContent = "Sample text before<br><br>" +
      "<table>\n<tr>\n<td>testdata</td><br></tr>\n</table>\n" +
      "Sample text <a href='http://clabs.org'>after</a><br>"
    @clWiki.updatePage('/TestPage', wikiPageModTime, updateContent)
    assert_equal(buildExpectedContent(testPage, readContent),
      @clWiki.displayPage(testPage).content)
  end

  def testDisplayEditPage
    @clWiki = ClWiki.new(@testWikiPath)
    testPage = '/TestPage'
    content = @clWiki.displayPageEdit(testPage)
    assert(content =~ /Describe TestPage here/)
  end

  def testFrontPageIfBadName
    assert_equal("/FrontPage", @clWiki.frontPageIfBadName("/FrontPage"))
    assert_equal("/FrontPage", @clWiki.frontPageIfBadName(""))
  end

  def buildExpectedContent(fullPageName, content = "")
    f = ClWikiPageFormatter.new(content, fullPageName)
    pageName = File.split(fullPageName)[-1]
    expectedContent = f.header(fullPageName)

    if content.empty?
      expectedContent << "Describe <a href=clwikicgi.rb?page=" + fullPageName + ">" + pageName + "</a> here.<br>"
    else
      expectedContent << content
    end

    expectedContent << f.footer(fullPageName)
  end

  def testMultiUserEdit
    exit
    # clwikifiletest has a multi user test

    testPageName = "/UpdatePage"
    # A and B read, same contents sent to both users
    expectedContent = buildExpectedContent(testPageName)
    wikiPageA = @clWiki.displayPage(testPageName)
    wikiPageB = @clWiki.displayPage(testPageName)
    assert_equal(expectedContent, wikiPageA.content)
    assert_equal(expectedContent, wikiPageB.content)
    modTimeA = wikiPageA.modTime
    modTimeB = wikiPageB.modTime

    sleep 3.5 # to ensure mtime changes. (lesser time sometimes doesn't work)

    @clWiki.updatePage(testPageName, modTimeA, "user A content")

    begin
      @clWiki.updatePage(testPageName, modTimeB, "user B content")
      assert(false, "Expected exception did not occur.")
    rescue ClWikiFileModifiedSinceRead
      # don't do anything, it's what should happen
    end

    # a bit of a tedious check
    # assert_equal(buildExpectedContent(testPageName, "user A content<br>"),
    #  @clWiki.displayPage(testPageName).content)
  end

  # def testWordWrap
  #   assert_equal("this \nis a \nword \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 4), "wrap at 4")
  #   assert_equal("this \nis a \nword \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 5), "wrap at 5")
  #   assert_equal("this is \na word \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 7), "wrap at 7")
  #   assert_equal("this \nis a word \nwrap test",
  #     @clWiki.wordWrap("this \nis a word wrap test", 10), "wrap at 10")

  #   assert_equal("this is a word wrap test",
  #     @clWiki.wordWrap("this is a word wrap test", 80), "wrap at 80")
  # end
end

class TestClWikiConf < TestBase
  def set_up
    super
    @testConfFile = @testWikiPath + '/testwiki.conf.xml'
  end

  def testReadPath
    f = File.new(@testConfFile, File::CREAT|File::TRUNC|File::RDWR)
    begin
      xml = <<-XML
        <ClWikiConf>
          <wikiPath>#{@testWikiPath}</wikiPath>
        </ClWikiConf>
      XML
      f.puts(xml)
      f.flush
    ensure
      f.close unless f.nil?
    end
    clWiki = ClWiki.new("", @testConfFile)
    assert_equal(@testWikiPath, clWiki.wikiPath)
  end
end