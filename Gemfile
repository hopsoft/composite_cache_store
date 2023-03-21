# frozen_string_literal: true

source "https://rubygems.org"

git "https://github.com/rails/rails.git" do
  gem "activesupport", require: "active_support" if ENV["COMPOSITE_CACHE_STORE_ENV"] == "test"
end

gemspec
