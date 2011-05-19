require 'ftools'
require 'rbconfig'

include Config

def get_path(prompt)
  goodPath = false
  while !goodPath
    puts prompt
    path = gets.chomp

    if !(File.directory?(File.expand_path(path)))
      puts "Directory does not exist. Create it? (Y/n)"
      reply = gets.chomp
      goodPath = (reply.upcase == 'Y')
      Dir.mkdir(path) if goodPath
    else
      goodPath = true
    end
  end
  path
end

SHEBANG_FILES = %w(
  blogki.editor.rb
  blogki.rb
  blogki.rss.rb
  clwikicgi.rb
  dot.rb
)

ALL_FILES = %w(
  clwiki.rb
  clwikiconf.rb
  clwikifile.rb
  clwikifiletest.rb
  clwikiindex.rb
  clwikiindex.rebuild.rb
  clwikipage.rb
  clwikipagetest.rb
  clwikitest.rb
  clwikitestbase.rb
  default.clwiki.conf
  findinfile.rb
  findinfiletest.rb
  install.rb
  runtests.rb
  sample.template.htm
  symlink.cgi.rb
  update.shebang.rb  

  doc/*  
  footer/*
  format/*
  graphviz/*
  tools/thunderbird.rb
) + SHEBANG_FILES

def copy_files(dest_dir, ruby_exe=nil)
  ALL_FILES.each do |fn_pattern|
    Dir[fn_pattern].each do |fn|
      if File.file?(fn)
        destfn = File.join(dest_dir, fn)
        File::makedirs(File.dirname(destfn))
        puts 'writing ' + destfn + '...'
        File.copy fn, destfn
      end
    end
  end

  set_shebang(dest_dir, ruby_exe)
  setup_cgi_links(dest_dir)
end

def set_shebang(dest_dir, ruby_exe=nil)
  if !ruby_exe
    ruby_exe = File.join(CONFIG["bindir"],
      CONFIG["ruby_install_name"] + CONFIG["EXEEXT"])
  end
  puts '---'
  puts 'setting shebang to ' + ruby_exe
  SHEBANG_FILES.each do |fn|
    destfn = File.join(dest_dir, fn)
    lines = File.readlines(destfn)
    puts 'writing ' + destfn + '...'
    File.open(destfn, 'w+') do |f|
      lines.each do |ln|
        ln = "#!#{ruby_exe}" if ln =~ /^#!/
        f.puts ln
      end
    end
    File.chmod(0755, destfn) # executable
  end
end

def setup_cgi_links(dest_dir)
  Dir.chdir(dest_dir) do
    files_to_cgi = {
      'blogki.editor.rb' => ['blogki.editor.cgi'],
      'blogki.rb' => ['blogki.cgi', 'index.cgi'],
      'blogki.rss.rb' => ['blogki.rss.cgi'],
      'clwikicgi.rb' => ['clwikicgi.cgi'],
    }
    
    files_to_cgi.each_pair { |src, dst_ary|
      dst_ary.each do |dst|
        File.unlink(dst) if File.exists?(dst)
        puts "Linking #{dst} to #{src} (if supported on platform)..."
        File.link(src, dst)
        puts "chmod #{src} 0755..." 
        File.chmod(0755, src)
      end
    }
  end
end

def repair_install(dest_dir)
  set_shebang(dest_dir)
  setup_cgi_links(dest_dir)
end

if __FILE__ == $0
  begin
    repair = ARGV.include?('--repair')
    if repair
      repair_install(File.dirname(__FILE__))
    else
      copy_files(get_path('Enter the path to install clWiki:'))
    end
  rescue Exception => e
    puts e.message + "\n" + e.backtrace.join("\n")
  end
end