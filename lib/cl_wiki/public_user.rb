# frozen_string_literal: true

module ClWiki
  class PublicUser < UserBase
    def name
      'public'
    end
  end
end
