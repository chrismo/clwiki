require_relative '../lib/cl_wiki/file'

class Updater
  def initialize(wiki_root_path)
    @wiki_root_path = wiki_root_path
  end

  def update_all_files
    glob = File.join("#{@wiki_root_path}", "*#{$wikiPageExt}")
    results = Dir[glob]
    results.each do |path_fn|
      f = ClWiki::File.new(File.basename(path_fn, $wikiPageExt), @wiki_root_path, $wikiPageExt, false)
      f.readFile
      meta_mtime = f.instance_variable_get("@metadata")['mtime']
      if meta_mtime
        p [f.name, f.modTimeAtLastRead, meta_mtime, File.mtime(path_fn)]
        File.utime(File.atime(path_fn), Time.parse(meta_mtime), path_fn)
      end
    end
  end
end

Updater.new(ARGV[0]).update_all_files
