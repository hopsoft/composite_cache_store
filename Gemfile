# frozen_string_literal: true

source "https://rubygems.org"

if ENV["GITHUB_ACTIONS"] || ENV["COMPOSITE_CACHE_STORE_ENV"] == "test"
  git "https://github.com/rails/rails.git" do
    gem "activesupport", require: "active_support"
  end
end

gemspec
