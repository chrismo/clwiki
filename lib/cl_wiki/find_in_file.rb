module ClWiki
  class FindInFile
    FULL_SEARCH = 0
    FILE_NAME_ONLY = 1

    attr_reader :find_path, :files

    def initialize(find_path)
      @find_path = find_path
    end

    def find(search_text, scope = FULL_SEARCH)
      recursive_find_path = ::File.join(@find_path, '**', "*#{$wikiPageExt}")
      regex = /#{search_text}/i
      @files = Dir[recursive_find_path].grep(regex)
      if scope == FULL_SEARCH
        Dir[recursive_find_path].each do |path_filename|
          if ::File.stat(path_filename).file?
            f = ::File.open(path_filename)
            begin
              @files << path_filename if f.grep(regex) != []
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