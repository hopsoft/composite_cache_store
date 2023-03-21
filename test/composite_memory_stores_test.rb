# frozen_string_literal: true

require "test_helper"

class CompositeMemoryStoresTest < MethodCallAssertionsTest
  # behaviors
  include CacheDeleteMatchedBehavior
  include CacheStoreVersionBehavior
  include EncodedKeyCacheBehavior

  # behavior overrides
  include CompositeCacheStoreBehavior
  include CompositeCacheIncrementDecrementBehavior
  include CompositeCacheStoreCoderBehavior

  # TODO: setup overrides for the following behaviors
  # include [Composite]LocalCacheBehavior
  # include [Composite]FailureSafetyBehavior
  # include [Composite]FailureRaisingBehavior
  # include [Composite]CacheInstrumentationBehavior

  def lookup_store(options = {})
    CompositeCacheStore.new options
  end

  setup do
    @cache = CompositeCacheStore.new(
      layers: [
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.second, size: 8.megabytes),
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute, size: 64.megabytes)
      ]
    )
  end

  def test_default_instantation
    store = CompositeCacheStore.new

    expected = {expires_in: 5.minutes, size: 16.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.layers.first.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.layers.first.options

    expected = {expires_in: 1.day, size: 32.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.layers.last.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.layers.last.options
  end

  def test_custom_instantation
    expected = {expires_in: 1.second, size: 8.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @cache.layers.first.options

    expected = {expires_in: 1.minute, size: 64.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @cache.layers.last.options
  end

  def test_invalid_instantation
    error = assert_raises(ArgumentError) do
      CompositeCacheStore.new(layers: [[], 1, true])
    end

    assert_equal "All layers must be instances of ActiveSupport::Cache::Store", error.message
  end

  test "write and read" do
    @cache.write(:test, "value")
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
  end

  test "read rewrites to layer-1 cache on layer-1 cache miss" do
    @cache.write(:test, "value")
    sleep 1
    assert_nil @cache.layers.first.read(:test) # layer-1 miss
    assert_equal "value", @cache.layers.last.read(:test) # layer-2 hit
    assert_equal "value", @cache.read(:test) # rewrites to layer-1
    assert_equal "value", @cache.layers.first.read(:test) # layer-1 hit
  end

  test "write_multi and read_multi" do
    hash = {a: 1, b: 2, c: 3}
    @cache.write_multi(hash)
    assert_equal hash, @cache.read_multi(:a, :b, :c)
    assert_equal hash, @cache.layers.first.read_multi(:a, :b, :c)
    assert_equal hash, @cache.layers.last.read_multi(:a, :b, :c)
  end

  test "read_multi rewrites to layer-1 cache on layer-1 cache miss" do
    hash = {a: 1, b: 2, c: 3}
    @cache.write_multi(hash)
    sleep 1
    assert @cache.layers.first.read_multi(:a, :b, :c).blank? # layer-1 miss
    assert_equal hash, @cache.layers.last.read_multi(:a, :b, :c) # layer-2 hit
    assert_equal hash, @cache.read_multi(:a, :b, :c) # rewrites to layer-1
    assert_equal hash, @cache.layers.first.read_multi(:a, :b, :c) # layer-1 hit
  end

  test "fetch" do
    @cache.fetch(:test) { "value" }
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
  end

  test "fetch rewrites to layer-1 cache on layer-1 cache miss" do
    @cache.write(:test, "value")
    sleep 1
    assert_nil @cache.layers.first.read(:test) # layer-1 miss
    assert_equal "value", @cache.layers.last.read(:test) # layer-2 hit
    @cache.fetch(:test) do # rewrites layer-1
      "value"
    end
    assert_equal "value", @cache.layers.first.read(:test) # layer-1 hit
  end

  test "delete " do
    @cache.write(:test, "value")
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
    @cache.delete(:test)
    assert_nil @cache.read(:test)
    assert_nil @cache.layers.first.read(:test)
    assert_nil @cache.layers.last.read(:test)
  end

  test "applies expires_in when value is less than cache's configured expires_in" do
    @cache.write(:test, "value", expires_in: 0.1.seconds)
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
    sleep 0.1
    assert_nil @cache.read(:test)
    assert_nil @cache.layers.first.read(:test)
    assert_nil @cache.layers.last.read(:test)
  end

  test "applies expires_at when computed expires_in is less than store's configured expires_in" do
    @cache.write(:test, "value", expires_at: 0.1.second.from_now)
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
    sleep 0.1
    assert_nil @cache.read(:test)
    assert_nil @cache.layers.first.read(:test)
    assert_nil @cache.layers.last.read(:test)
  end
end
