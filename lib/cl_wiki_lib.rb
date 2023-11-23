# frozen_string_literal: true

require File.expand_path('cl_wiki/configuration', __dir__)
require File.expand_path('cl_wiki/user_base', __dir__)
require File.expand_path('cl_wiki/public_user', __dir__)
require File.expand_path('cl_wiki/memory_indexer', __dir__)

require File.expand_path('cl_wiki/file_error', __dir__)
require File.expand_path('cl_wiki/file_modified_since_read', __dir__)
require File.expand_path('cl_wiki/file', __dir__)

require File.expand_path('cl_wiki/util', __dir__)

require File.expand_path('cl_wiki/custom_footer', __dir__)
require File.expand_path('cl_wiki/custom_footers', __dir__)
require File.expand_path('cl_wiki/custom_formatter', __dir__)
require File.expand_path('cl_wiki/custom_formatters', __dir__)

Dir[File.join(__dir__, 'cl_wiki', 'format_*.rb')].each do |fn|
  require fn
end


require File.expand_path('cl_wiki/metadata', __dir__)
require File.expand_path('cl_wiki/page_formatter', __dir__)

require File.expand_path('cl_wiki/page', __dir__)
require File.expand_path('cl_wiki/version', __dir__)
