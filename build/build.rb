require 'ftools'
require 'fileutils'
require 'rubygems'
gem 'clutil'
require 'cl/util/console'
require 'cl/util/file'
require 'cl/util/win'

$LOAD_PATH << '..'
require 'clwiki'
require 'install'

module CLabs
  module Wiki
    VERSION = ClWiki::VERSION

    def do_system(cmd)
      puts cmd if if_switch('-v')
      system(cmd)
    end

    def dl_url
      "dl/clwiki/#{zipfn}"
    end

    def rootname
      "clwiki.#{VERSION.to_s}"
    end

    def zipfn
      "#{rootname}.zip"
    end

    def do_build
      root_dir = File.expand_path("./#{rootname}")

      Dir.chdir('..') do 
        copy_files(root_dir, 'ruby')
      end

      # File.copy '../doc/License', doc_dir
      # rlines = File.readlines('../doc/Readme')
      # File.open(File.join(doc_dir, 'Readme'), 'w+') do |f|
      #   rlines.each do |ln|
      #     ln.gsub!(/Download:: (.*)/, "Download:: #{dl_url}")
      #     f.puts ln
      #   end
      # end

      # Dir.chdir(rootDir)
      # # this puts License.html and Readme.html in rdoc/files/_/doc/
      # # they'll need to be dug out if they will be the web page home page
      # do_system('rdoc -o ./doc/rdoc ./doc/License ./doc/Readme')
      # do_system('rdoc -o ./doc/rdoc cl')
      # Dir.chdir('..')
      # do_system('pause')

      FileUtils.rm_rf('../dist')
      do_system("md ..\\dist")
      do_system("zip -r ..\\dist\\#{zipfn} #{rootname}")
      sleep 2
      ClUtilFile.delTree("#{rootname}")

      if if_switch('-clabs')
        puts "updating scrplist.xml..."
        fsize = (File.size("../dist/#{zipfn}") / 1000).to_s + 'k'
        require 'c:/dev/cvslocal/cweb/clabs/scrplist.rb'
        slist = get_slist
        slist.groups.each do |group|
          group.items.each do |sitem|
            if sitem.name =~ /clWiki/
              sitem.version = VERSION.to_s
              sitem.date = Time.now.strftime("%m/%d/%Y")
              dl = sitem.downloads[0]
              dl.name = zipfn
              dl.link = dl_url
              dl.size = fsize
            end
          end
        end
        write_slist(slist)
  
        puts "copying .zip to clabs dist..."
        cp_dest_dir = "c:/dev/cvslocal/cweb/clabs/bin/dl/clwiki"
        File.makedirs(cp_dest_dir)
        File.copy "../dist/#{zipfn}", File.join(cp_dest_dir, "#{zipfn}")
      end
      do_system('pause')
    end
  end
end

if __FILE__ == $0
  def show_help
    puts '-h      show help'
    puts '-v      verbose output'
    puts
    puts '-clabs  do steps to update cLabs website'
  end
  
  def need_help
    if_switch('-h')
  end

  if need_help
    show_help
  else
    include CLabs::Wiki
    do_build
  end
end