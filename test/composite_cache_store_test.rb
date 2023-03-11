# frozen_string_literal: true

require_relative "test_helper"

class CompositeCacheStoreTest < ActiveSupport::TestCase
  setup do
    @logger = Logger.new("/dev/null") # used for Standard/Rubocop shenanigans

    # NOTE: The inner cache store would normally use a shared persistence service like
    #       Redis via ActiveSupport::Cache::RedisCacheStore
    #
    #       In a Rails app you might use Rails.cache as the inner cache store
    @store = CompositeCacheStore.new(
      inner_cache_store: ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute, size: 64.megabytes),
      outer_cache_store: ActiveSupport::Cache::MemoryStore.new(expires_in: 1.second, size: 8.megabytes)
    )
  end

  test "default instantation" do
    store = CompositeCacheStore.new

    expected = {expires_in: 5.minutes, size: 16.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.outer.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.outer.options

    expected = {expires_in: 1.day, size: 32.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.inner.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.inner.options
  end

  test "custom instantation" do
    expected = {expires_in: 1.second, size: 8.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @store.outer.options

    expected = {expires_in: 1.minute, size: 64.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @store.inner.options
  end

  test "write and read" do
    @store.write(:test, "value")
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.outer.read(:test)
    assert_equal "value", @store.inner.read(:test)
  end

  test "read rewrites to outer cache on outer cache miss" do
    @store.write(:test, "value")
    sleep 1
    assert_nil @store.outer.read(:test) # outer cache miss
    assert_equal "value", @store.inner.read(:test) # inner cache hit
    assert_equal "value", @store.read(:test) # rewrites the outer cache
    assert_equal "value", @store.outer.read(:test) # outer cache hit
  end

  test "fetch" do
    @store.fetch(:test) do
      @logger.debug "Prevent Standard/Rubocop from jacking up the fetch block ¯\\_(ツ)_/¯"
      "value"
    end
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.outer.read(:test)
    assert_equal "value", @store.inner.read(:test)
  end

  test "fetch rewrites to outer cache on outer cache miss" do
    @store.write(:test, "value")
    sleep 1
    assert_nil @store.outer.read(:test) # outer cache miss
    assert_equal "value", @store.inner.read(:test) # inner cache hit
    @store.fetch(:test) do # rewrites the outer cache
      @logger.debug "Prevent Standard/Rubocop from jacking up the fetch block ¯\\_(ツ)_/¯"
      "value"
    end
    assert_equal "value", @store.outer.read(:test) # outer cache hit
  end

  test "delete" do
    @store.write(:test, "value")
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.outer.read(:test)
    assert_equal "value", @store.inner.read(:test)
    @store.delete(:test)
    assert_nil @store.read(:test)
    assert_nil @store.outer.read(:test)
    assert_nil @store.inner.read(:test)
  end
end
