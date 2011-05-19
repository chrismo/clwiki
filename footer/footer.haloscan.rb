# Note: for this to work, you must use a template and put the haloscan
# required <script> tag in the <head> section of the template.

class HaloscanCommentFooter < ClWikiCustomFooter
  def HaloscanCommentFooter.footer_html(page)
    # blogki view somehow hands us a string instance
    # (code in clwikipage.rb protects this now, but, still may be
    # a good idea to protect it)
    if page.is_a? ClWikiPage
      page_id = page.fullName.gsub(/\//, '_')
      "<table width='100%' noborder><tr><td align=right><a href=\"javascript:HaloScan('#{page_id}');\" target=\"_self\"><script type=\"text/javascript\">postCount('#{page_id}');</script></a> | <a href=\"javascript:HaloScanTB('#{page_id}');\" target=\"_self\"><script type=\"text/javascript\">postCountTB('#{page_id}'); </script></a></td></tr></table>"
    else
      ''
    end
  end
end

# ** Un-remark the following line to register this footer **
# ClWikiCustomFooters.instance.register(HaloscanCommentFooter)
