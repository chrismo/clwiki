$LOAD_PATH << '..'
require 'clwikipage'
require 'cl/util/console'
require 'cl/util/smtp'

PageDepth = Struct.new("PageDepth", :name, :depth)

def read_page(pageName)
  content = ''
  @stack.push PageDepth.new(pageName, 0)
  while !@stack.empty?
    pageDepth = @stack.shift
    @depth = pageDepth.depth
    pageName = pageDepth.name

    if @depth <= @depthLimit
      content << "\n" + pageName + "\n" + ("=" * pageName.length) + "\n"
      page = ClWikiPage.new(pageName, @wikiPath)
      page.read_raw_content
      formatter = ClWikiPageFormatter.new(page.raw_content, pageName)
      content << formatter.formatLinks do |word|
        if formatter.isWikiName?(word)
          wikiPageName = word
          wikiPageName = '/' + wikiPageName if wikiPageName[0..0] != '/'
          if !@visited.include?(wikiPageName)
            @visited << wikiPageName
            @stack.push PageDepth.new(wikiPageName, @depth + 1)
          end
          wikiPageName
        else
          word
        end
      end
      content << "\n"
    end
    @stack.delete_if { |pgd| pgd.name =~ /journal/i }
  end
  content
end

def show_help
  puts '-pn     Page name. Must be full path.'
  puts '-wp     Wiki path.'
end

@visited = []
@stack = []
@depthLimit = 2
@depth = 0
pageName = get_switch('-pn')
@wikiPath = get_switch('-wp')
content = read_page(pageName)
puts content
puts
File.open('singlepage.out.txt', 'w+') do |f| f.puts content end



