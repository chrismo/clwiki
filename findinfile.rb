# $Id: findinfile.rb,v 1.7 2005/05/30 19:27:51 chrismo Exp $
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

class FindInFile
  FULL_SEARCH = 0
  FILE_NAME_ONLY = 1

  attr_reader :findPath, :files

  def initialize(findPath)
    @findPath = findPath
  end

  def find(searchText, scope = FULL_SEARCH)
    # refactor out reg expression duplication
    recursiveFindPath = File.join(@findPath, '**', '*')
    @files = Dir[recursiveFindPath].grep(/#{searchText}/i)
    if scope == FULL_SEARCH
      Dir[recursiveFindPath].each do |pathfilename|
        if File.stat(pathfilename).file?
          f = File.open(pathfilename)
          begin
            # refactor out reg expression duplication
            @files << pathfilename if f.grep(/#{searchText}/i) != []
          ensure
            f.close unless f.nil?
          end
        end
      end
    end
    @files.collect! { |fn| fn.sub(@findPath + '/', '') } 
    @files.uniq!
    @files.length
  end
end