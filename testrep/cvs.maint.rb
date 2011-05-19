require 'cl/util/win'

def execute
  r = `cvs -n up`;                                                       puts r if @verbose
  a = r.split("\n");                                                     puts a.inspect if @verbose
  a.collect! { |item| item.slice(2..item.length) if item[0..0] == "?" }; puts a.inspect if @verbose
  a.compact!;                                                            puts a.inspect if @verbose
  if a.length > 0
    cmd = 'cvs add ' + a.join(" ");                                      puts cmd if @verbose
    r = `#{cmd}`;                                                        puts r if @verbose
  end
  cmd = "cvs commit -m cvs.maint.rb";                                    puts cmd if @verbose
  r = `#{cmd}`;                                                          puts r if @verbose
end

begin
  @verbose = true # if ARGV[0] == '-v'
  execute
rescue Exception => e
  puts e.message + "\n" + e.backtrace.join("\n")
end
system('pause')