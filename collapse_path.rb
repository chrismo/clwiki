def collapse_path_nobu(path, base)
  head, = path.split("/", 2)
  base.rindex(%r"(\A|.*/)#{Regexp.quote(head)}(?:/|\z)")
  ($1 or base.sub(%r|[^/]\z|, '\&/')) + path
end

def collapse_path1_pit( path, base )
  abs_path = path
  abs_path = '/' + path if path[0] != '/' 
  pattern = Regexp.quote( abs_path.sub( /(.)\/.*/, '\1' ) )
  base.sub( /(.*)#{pattern}(\/|$).*/, '\1' ) + abs_path
end

def collapse_path_ts(p, m)
  if %r{^([^\0]*/)([^\0]+)(?:/|\z)[^\0]*\0\2(.*)} =~  m + "\0" + p
     $1+ $2 + $3
  else 
     if p[0] == ?/
        p
     else
  m + "/" + p
     end
  end
end


def collapse_path_cl(partial, reference)
  # "" is in [0] if partial is an absolute
  partialPieces = partial.split('/').delete_if { |p| p == "" }
  matchFound = false
  result = ''
  (partialPieces.length-1).downto(0) do |i|
    thisPartial = partialPieces[0..i].join('/')
    matchLoc = (reference.rindex(/#{thisPartial}/))
    if matchLoc
      matchFound = true
      result = reference[0..(matchLoc + thisPartial.length-1)]
      partialRemainder = partialPieces[i+1..-1]
      result = File.join(result, partialRemainder)
      result.chop! if result[-1..-1] == '/'
      break
    end
  end
  result = File.expand_path(partial, reference) if !matchFound
  
  # if ('/a/b', '/') passed, then '//' ends up at front because
  # this is not illegal at the very first in File.expand_path
  result = result[1..-1] if result[0..1] == '//'
  result
end

if $0 == __FILE__
  require "test/unit"
  
  puts RUBY_VERSION, RUBY_PLATFORM
  
  class TC_collapse_path < Test::Unit::TestCase
    def test_collapse_path_nobu
      assert_equal("/a/b/c", collapse_path_nobu("b/c", "/a/b/c/d/e"))
      assert_equal("/a/b", collapse_path_nobu("b", "/a/b/c/d/e"))
      assert_equal("/a/b/c/f", collapse_path_nobu("b/c/f", "/a/b/c/d/e"))
      assert_equal("/a/b/c/d/e/m/n/o", collapse_path_nobu("m/n/o", "/a/b/c/d/e"))
      assert_equal("/a/b/c/a/b/d", collapse_path_nobu("a/b/d", "/a/b/c/a/b/c"))
      assert_equal("/a/b", collapse_path_nobu("/a/b", "/"))
      assert_equal("/m/n", collapse_path_nobu("/m/n", "/a/b"))
    end
    
    def test_collapse_path1_pit
      assert_equal("/a/b/c", collapse_path1_pit("b/c", "/a/b/c/d/e"))
      assert_equal("/a/b", collapse_path1_pit("b", "/a/b/c/d/e"))
      assert_equal("/a/b/c/f", collapse_path1_pit("b/c/f", "/a/b/c/d/e"))
      assert_equal("/a/b/c/d/e/m/n/o", collapse_path1_pit("m/n/o", "/a/b/c/d/e"))
      assert_equal("/a/b/c/a/b/d", collapse_path1_pit("a/b/d", "/a/b/c/a/b/c"))
      assert_equal("/a/b", collapse_path1_pit("/a/b", "/"))
      assert_equal("/m/n", collapse_path1_pit("/m/n", "/a/b"))
    end
    
    def test_collapse_path_ts
      assert_equal("/a/b/c", collapse_path_ts("b/c", "/a/b/c/d/e"))
      assert_equal("/b/c", collapse_path_ts("/b/c", "/a/b/c/d/e"))
      assert_equal("/a/b", collapse_path_ts("b", "/a/b/c/d/e"))
      assert_equal("/a/b/c/f", collapse_path_ts("b/c/f", "/a/b/c/d/e"))
      assert_equal("/a/b/c/d/e/m/n/o", collapse_path_ts("m/n/o", "/a/b/c/d/e"))
      assert_equal("/a/b/c/a/b/d", collapse_path_ts("a/b/d", "/a/b/c/a/b/c"))
      assert_equal("/a/b", collapse_path_ts("/a/b", "/"))
      assert_equal("/m/n", collapse_path_ts("/m/n", "/a/b"))
    end

    def test_collapse_path_cl
      assert_equal("/a/b/c", collapse_path_cl("b/c", "/a/b/c/d/e"))
      assert_equal("/b/c", collapse_path_cl("/b/c", "/a/b/c/d/e"))
      assert_equal("/a/b", collapse_path_cl("b", "/a/b/c/d/e"))
      assert_equal("/a/b/c/f", collapse_path_cl("b/c/f", "/a/b/c/d/e"))
      assert_equal("/a/b/c/d/e/m/n/o", collapse_path_cl("m/n/o", "/a/b/c/d/e"))
      assert_equal("/a/b/c/a/b/d", collapse_path_cl("a/b/d", "/a/b/c/a/b/c"))
      assert_equal("/a/b", collapse_path_cl("/a/b", "/"))
      assert_equal("/m/n", collapse_path_cl("/m/n", "/a/b"))
    end
  end
end


