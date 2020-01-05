$LOAD_PATH << File.dirname(__FILE__) + '/../../../lib/cl_wiki'

require_relative 'test_base'

require 'minitest/autorun'

class EncryptingUser < ClWiki::UserBase
  def initialize(name = 'encrypting test user')
    @name = name
  end

  def name
    @name
  end

  def can_encrypt?
    true
  end

  def encryption_key
    '0' * 64
  end
end
