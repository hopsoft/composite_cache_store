# frozen_string_literal: true

require "bundler"
require "pry-byebug"

spec = Bundler.locked_gems.specs.find { |spec| spec.name == "activesupport" }
path = spec.source.install_path
$LOAD_PATH.prepend path.join("activesupport/test")
$LOAD_PATH.prepend path.join("activesupport/lib") # needed by activerecord test files that require activesupport lib files

require "active_support/all"
require "testing/method_call_assertions_test" # path: activesupport/test/testing/method_call_assertions_test.rb
require "cache/behaviors" # path: activesupport/test/cache/behaviors.rb

# cache test behavior overrides
require "behaviors/composite_cache_store_behavior"
require "behaviors/composite_cache_increment_decrement_behavior"
require "behaviors/composite_cache_store_coder_behavior"

require "minitest/reporters"
Minitest::Reporters.use!

require_relative "../lib/composite_cache_store"
