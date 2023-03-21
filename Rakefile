# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "colorize"

task default: :test

Minitest::TestTask.create(:minitest) do |t|
  t.test_globs = ["test/**/*_test.rb"]
end

task :test do
  print "Bundling with activesupport from github ".colorize(:blue)
  print "(required for tests provided by rails)... ".colorize(:light_blue)
  `bundle`
  ENV["COMPOSITE_CACHE_STORE_ENV"] = "test"
  `bundle update activesupport`
  puts "done!".colorize(:blue)
  Rake::Task["minitest"].invoke
ensure
  ENV["COMPOSITE_CACHE_STORE_ENV"] = nil
  print "Restoring bundle with activesupport from rubygems... ".colorize(:blue)
  `rm -rf Gemfile.lock && bundle`
  puts "done!".colorize(:blue)
end
