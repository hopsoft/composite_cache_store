# frozen_string_literal: true

require_relative "lib/composite_cache_store/version"

Gem::Specification.new do |s|
  s.name = "composite_cache_store"
  s.version = CompositeCacheStore::VERSION
  s.authors = ["Nate Hopkins (hopsoft)"]
  s.email = ["natehop@gmail.com"]

  s.summary = "A composite cache store comprised of layered ActiveSupport::Cache::Store instances"
  s.description = <<~DESC
    Enhanced application performance with faster reads, data redundancy,
    and reduced backpressure on the outer cache store.
  DESC

  s.homepage = "https://github.com/hopsoft/composite_cache_store"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.7.5"

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = s.homepage + "/blob/main/CHANGELOG.md"

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 6.0"

  s.add_development_dependency "magic_frozen_string_literal"
  s.add_development_dependency "minitest-reporters"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "standardrb"
end
