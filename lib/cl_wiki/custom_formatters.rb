module ClWiki
  class CustomFormatters
    include Singleton

    def register(class_ref)
      @formatters ||= []
      @formatters << class_ref
    end

    def unregister(class_ref)
      @formatters.delete(class_ref)
    end

    def process_formatters(content, page)
      @formatters&.each do |f|
        if content&.match?(f.match_re)
          content.gsub!(f.match_re) { |match| f.format_content(match, page) }
        end
      end
    end
  end
end
