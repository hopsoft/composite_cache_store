# frozen_string_literal: true

require_relative "lib/turbo_boost/cache/version"

Gem::Specification.new do |s|
  s.name = "turbo_boost-cache"
  s.version = TurboBoost::Cache::VERSION
  s.authors = ["Nate Hopkins (hopsoft)"]
  s.email = ["natehop@gmail.com"]

  s.summary = "A layered cache that implements the same interface as ActiveSupport::Cache::Store"
  s.description = <<~DESC
    A layered cache that wraps an inner cache with ActiveSupport::Cache::MemoryStore
    which improves read performance and limits inner cache backpressure.
  DESC

  s.homepage = "https://github.com/hopsoft/turbo_boost-cache"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.6.0"

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = s.homepage + "/blob/main/CHANGELOG.md"

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 6.0"

  s.add_development_dependency "standardrb"
  s.add_development_dependency "magic_frozen_string_literal"
end
