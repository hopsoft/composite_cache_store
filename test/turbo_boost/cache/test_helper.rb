require "active_support/test_case"
require "minitest/reporters"
require "pry"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require_relative "../../../lib/turbo_boost/cache"
