# frozen_string_literal: true

require "active_support/cache"

class CompositeCacheStore < ActiveSupport::Cache::Store
  VERSION = "0.0.3"
end
