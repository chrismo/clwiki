module ClWiki
  class Util
    def self.raise_if_mtime_not_equal(mtime_to_compare, file_name)
      # reading the instance .mtime appears to take Windows DST into account,
      # whereas the static File.mtime(filename) method does not
      current_mtime = ::File.open(file_name, &:mtime)
      compare_read_times!(mtime_to_compare, current_mtime)
    end

    def self.compare_read_times!(a, b)
      # ignore usec
      a = Time.new(a.year, a.month, a.day, a.hour, a.min, a.sec)
      b = Time.new(b.year, b.month, b.day, b.hour, b.min, b.sec)
      if a != b
        raise FileModifiedSinceRead, "File has been modified since it was last read. #{dump_time(a)} != #{dump_time(b)}"
      end
    end

    def self.dump_time(time)
      String.new.tap do |s|
        s << time.to_s
        s << ".#{time.usec}" if time.respond_to?(:usec)
      end
    end

    def self.convert_to_native_path(path)
      path.gsub(%r{/}, ::File::SEPARATOR).gsub(/\\/, ::File::SEPARATOR)
    end
  end
end
