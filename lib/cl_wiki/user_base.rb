# frozen_string_literal: true

require 'lockbox'

module ClWiki
  class UserBase
    def name
      raise 'Subclass must implement'
    end

    def can_encrypt?
      false
    end

    def lockbox
      raise 'User cannot encrypt?' unless can_encrypt?

      Lockbox.new(key: encryption_key)
    end

    def encryption_key
      raise 'Subclass must implement'
    end
  end
end
