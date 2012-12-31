module ClWiki
  class FindInFile
    FULL_SEARCH = 0
    FILE_NAME_ONLY = 1

    attr_reader :find_path, :files

    def initialize(find_path)
      @find_path = find_path
    end

    def find(searchText, scope = FULL_SEARCH)
      # refactor out reg expression duplication
      recursiveFindPath = ::File.join(@find_path, '**', '*')
      @files = Dir[recursiveFindPath].grep(/#{searchText}/i)
      if scope == FULL_SEARCH
        Dir[recursiveFindPath].each do |pathfilename|
          if ::File.stat(pathfilename).file?
            f = ::File.open(pathfilename)
            begin
              # refactor out reg expression duplication
              @files << pathfilename if f.grep(/#{searchText}/i) != []
            ensure
              f.close unless f.nil?
            end
          end
        end
      end
      @files.collect! { |fn| fn.sub(@find_path + '/', '') }
      @files.uniq!
      @files.length
    end
  end
end