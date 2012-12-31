# modified version of Cron class by John Small mailto:jsmall@laser.net
# RAA entry as of 1/2/03 is defunct - web site is bad url

# next step -- every minute write to file the time
# then, every minute, verify the previous minute written to file matches.
# if not, then simulate every minute in between time and call testAndLaunch
# ... this way missed time will be caught up

# other approach is to prefigure when items should go and write them to a log
# then delete them from the log when they are sent -- and do a catch up
# on every check

require 'cl/util/console'
require 'cl/util/win'
require 'rubygems'
gem 'mosmtp', '>= 2010.141.2'
require 'mosmtp'
$LOAD_PATH << '..'
require 'clwikiconf'
require 'clwikipage'
require 'parsedate'

class Cron
  def loadCrontab()
    File.open(@crontabFilename, "r") do |f|
      @crontab = []
      f.each_line { | line |
        line.chomp!
        next if (line =~ /^$/)  # skip blank lines
        next if (line =~ /^\#/)  # skip comments
        @crontab << line.split(/ +/,6)
      }
    end
    @crontabAge = File.mtime(@crontabFilename)
  end

  def inRange(value,range)
    range.split(/,/).each { | subrange |
      low, high = subrange.split(/\-/)
      low = low.to_i
      if high
        high = high.to_i
        return true if value >= low and value <= high;
      else
        return true if low == value;
      end
    }
    false
  end

  def nth_wday_of_month?(nth)
    require 'date'

    all_wday_in_month = []
    today = Date.today
    (-5..5).each do |i|
      a_date = (today + (i*7))
      all_wday_in_month << a_date if a_date.mon == today.mon
    end
    all_wday_in_month[nth - 1] == today
  end

  def wday_in_range(current_wday, tweekday)
    tweekday, nth_wday = tweekday.split('/')
    result = inRange(current_wday, tweekday)
    if result && nth_wday
      result = nth_wday_of_month?(nth_wday.to_i)
    end
    result
  end

  def testAndLaunch(now)
    @crontab.each { | task |
      tmin, thour, tmonthday, tmonth, tweekday, tcommand = task
      launch = false

      # Launch this month of the year?
      if tmonth.eql?("*") || inRange(now.mon,tmonth)
        launch = true
      end

      # Launch this day of the month?
      if launch && !tmonthday.eql?("*") &&
        !inRange(now.mday,tmonthday)
        launch = false
      end

      # Launch this day of the week?
      if launch && !tweekday.eql?("*") &&
        !wday_in_range(now.wday, tweekday)
        launch = false
      end

      # Launch this hour of the day?
      if launch && !thour.eql?("*") &&
        !inRange(now.hour,thour)
        launch = false
      end

      # Launch this minute of the hour?
      if launch && !tmin.eql?("*") &&
        !inRange(now.min,tmin)
        launch = false;
      end

      if launch || $debug
        subj = "[rem] " + tcommand.gsub(/_/, ' ')
        body = time_to_str(now) + "\n" + parse_tcommand_for_wiki_pages(tcommand) + "\n" +
               "\n" +
               "http://localhost/clwiki/clwikicgi.rb?page=/UrgentToDo"
        to = 'chrismo@clabs.org'
        msg_id = "#{subj.scan(/[A-Za-z0-9]/).to_s}@clabs.org"
        do_sendmail(to, 'chrismo@clabs.org', subj, body, msg_id)
        puts 'sent ' + subj + "\n" +
          ('-' * (subj.length + 5)) + "\n" +
          body + "\n" if @verbose
      end
    }
  end

  def parse_tcommand_for_wiki_pages(tcommand)
    content = ''
    content << tcommand + "\n\n"
    formatter = ClWikiPageFormatter.new(tcommand, '/UrgentToDo')
    formatter.formatLinks do |word|
      if formatter.isWikiName?(word)
        wiki_page_name = word
        ref_page_full_name = formatter.expand_path(wiki_page_name, '/UrgentToDo')
        puts ref_page_full_name
        if ClWikiPage.page_exists?(ref_page_full_name)
          ref_page = ClWikiPage.new(ref_page_full_name, $wiki_path)
          ref_page.read_raw_content
          content << ref_page_full_name << "\n" <<
            ('-' * ref_page_full_name.length) << "\n\n" <<
            ref_page.raw_content << "\n"
        end
      end
    end
    content
  end

  def initialize(crontabFilename,verbose=false)
    @crontabAge = 0
    @lines = 0
    @verbose = verbose
    @crontabFilename = crontabFilename
  end

  def str_to_time(str)
    begin
      Time.local(*([ParseDate.parsedate(str)[0..4], 0].flatten))
    rescue => e
      puts(str.inspect)
      raise e
    end
  end

  def time_to_str(time)
    time.strftime("%m/%d/%Y %H:%M")
  end

  def run()
    if @verbose
      print "\n\nDO NOT CLOSE THIS WINDOW!\n\n"
    end
    while (true)
      if @crontabAge != File.mtime(@crontabFilename)
        loadCrontab()
      end

      if $debug
        testAndLaunch(Time.now)
      else
        # we do this to strip the seconds off for pure minute comparisons
        now = str_to_time(time_to_str(Time.now))

        lastrun_fn = 'cron.reminders.lastrun'
        if File.exists?(lastrun_fn)
          lastruntime = File.readlines(lastrun_fn)[0]
          if lastruntime.nil?
            File.delete(lastrun_fn)
            next
          end
          lastrun = str_to_time(lastruntime.chomp)
        else
          # default to starting a week ago, that should be enough catchup
          lastrun = now - (60 * 60 * 24 * 7)
        end
        nextrun = lastrun + (60)
        catchup = false
        if nextrun < now
          catchup = true
          time_do = nextrun
        elsif nextrun == now
          time_do = now
        else
          time_do = nil
        end
        if time_do
          puts 'catching up ' + time_to_str(time_do) if catchup
          #puts 'doing ' + time_to_str(time_do) if @verbose
          testAndLaunch(time_do)
          File.open(lastrun_fn, 'w') do |f| f.puts time_to_str(time_do) end
        end
        sleep (60) if !catchup
      end
      break if $debug
    end
  end
end

def do_sendmail(to, from, subj, body, msg_id)
  smtp = MoSmtp.new
  smtp.subj = subj
  smtp.body = body
  smtp.extra_headers = ["In-Reply-To: #{msg_id}", "References: #{msg_id}"]
  smtp.sendmail
end


if __FILE__ == $0
  begin
    $debug = if_switch('-d')
    $wiki_path = get_switch('-wp')
    raise 'no wikiPath specified' if !$wiki_path
    $wiki_conf = ClWikiConfiguration.new
    $wiki_conf.useIndex = ClWikiConfiguration::USE_INDEX_NO
    crontabFilename = 'c:/Dev/svn.momo/cweb/wikirep/UrgentToDo.txt';
    Cron.new(crontabFilename, true).run()
  rescue Exception => e
    msgsummary = e.message + "\n" + e.backtrace.join("\n")
    File.open('cron.reminders.err.txt', 'a+') do |f|
      f.puts Time.now.to_s
      f.puts msgsummary
    end
    do_sendmail('chrismo@clabs.org', 'chrismo@clabs.org', 'cron.reminders err',
      msgsummary, "remindererr@clabs.org")
    puts msgsummary
  end
  system 'pause'
end
