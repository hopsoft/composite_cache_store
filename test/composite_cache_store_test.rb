# frozen_string_literal: true

require_relative "test_helper"
require "active_support/testing/method_call_assertions"

require "active_support/cache"
require_relative "behaviors/cache_store_behavior"
require_relative "behaviors/cache_store_version_behavior"
require_relative "behaviors/cache_store_coder_behavior"
require_relative "behaviors/local_cache_behavior"
require_relative "behaviors/cache_increment_decrement_behavior"
require_relative "behaviors/cache_instrumentation_behavior"
require_relative "behaviors/encoded_key_cache_behavior"

module CompositeCacheStoreTests
  class StoreTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::MethodCallAssertions

    setup do
      @logger = Logger.new("/dev/null") # used for Standard/Rubocop shenanigans

      # NOTE: The inner cache store would normally use a shared persistence service like
      #       Redis via ActiveSupport::Cache::RedisCacheStore
      #
      #       In a Rails app you might use Rails.cache as the inner cache store
      @cache = CompositeCacheStore.new(
        layers: [
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.second, size: 8.megabytes),
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute, size: 64.megabytes)]
      )
    end

    def lookup_store(options = {})
      # TODO in case of upstreaming to Rails, add active_support/cache/composite_cache_store
      # ActiveSupport::Cache.lookup_store(:composite_cache_store, options)
      @cache
    end
  end

  class CompositeCacheStoreCommonBehaviorTest < StoreTest
    include CacheStoreBehavior
    include CacheStoreVersionBehavior
    # include CacheStoreCoderBehavior
    # include LocalCacheBehavior
    # include CacheIncrementDecrementBehavior
    include CacheInstrumentationBehavior
    # include EncodedKeyCacheBehavior
  end
end
