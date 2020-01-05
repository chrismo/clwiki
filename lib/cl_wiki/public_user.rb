require File.expand_path('user_base', __dir__)

module ClWiki
  class PublicUser < UserBase
    def name
      'public'
    end
  end
end