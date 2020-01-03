require_relative '../lib/cl_wiki/file'

class Updater
  def initialize(wiki_root_path)
    @wiki_root_path = wiki_root_path
  end

  def update_all_files
    glob = File.join("#{@wiki_root_path}", "*#{ClWiki::FILE_EXT}")
    results = Dir[glob]
    results.each do |path_fn|
      f = ClWiki::File.new(File.basename(path_fn, ClWiki::FILE_EXT), @wiki_root_path, auto_create: false)
      f.read_file
      meta_mtime = f.instance_variable_get("@metadata")['mtime']
      if meta_mtime
        p [f.name, f.mod_time_at_last_read, meta_mtime, File.mtime(path_fn)]
        File.utime(File.atime(path_fn), Time.parse(meta_mtime), path_fn)
      end
    end
  end
end

Updater.new(ARGV[0]).update_all_files
