# frozen_string_literal: true

require_relative '../../../lib/cl_wiki_lib'
require File.expand_path('test_base', __dir__)

require 'minitest/autorun'

class EncryptingUser < ClWiki::UserBase
  attr_reader :name

  def initialize(name = 'encrypting test user')
    @name = name
  end

  def can_encrypt?
    true
  end

  def encryption_key
    '0' * 64
  end
end
