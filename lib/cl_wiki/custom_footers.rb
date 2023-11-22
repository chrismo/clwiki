module ClWiki
  class CustomFooters
    include Singleton

    def register(class_ref)
      @footers ||= []
      @footers << class_ref
    end

    def process_footers(page)
      String.new.tap do |content|
        @footers&.each do |f|
          content << f.footer_html(page)
        end
      end
    end
  end
end
