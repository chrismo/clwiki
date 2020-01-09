require_relative '../../../lib/cl_wiki_lib'
require File.expand_path('test_base', __dir__)

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
