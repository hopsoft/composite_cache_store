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

  def new_layered_memory_store(options = {})
    CompositeCacheStore.new(
      layers: [
        ActiveSupport::Cache::MemoryStore.new(options.merge(expires_in: 1.second, size: 8.megabytes)),
        ActiveSupport::Cache::MemoryStore.new(options.merge(expires_in: 1.minute, size: 64.megabytes))
      ]
    )
  end

  def lookup_store(options = {})
    new_layered_memory_store options
  end

  setup do
    @cache = new_layered_memory_store
  end

  def test_default_instantation
    error = assert_raises(ArgumentError) do
      CompositeCacheStore.new
    end

    assert_equal "A layered cache requires more than 1 layer!", error.message
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

    assert_equal "All layers must be instances of ActiveSupport::Cache::Store!", error.message
  end

  def test_write_and_read
    @cache.write(:test, "value")
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
  end

  def test_read_miss_on_layer_1_and_read_hit_on_layer_2_without_side_effects
    @cache.write(:test, "value")
    sleep 1
    assert_equal "value", @cache.read(:test) # layer-1 miss, layer-2 hit
    assert_nil @cache.layers.first.read(:test) # layer-1 miss
    assert_equal "value", @cache.layers.last.read(:test) # layer-2 hit
  end

  def test_write_multi_and_read_multi
    hash = {a: 1, b: 2, c: 3}
    @cache.write_multi(hash)
    assert_equal hash, @cache.read_multi(:a, :b, :c)
    assert_equal hash, @cache.layers.first.read_multi(:a, :b, :c)
    assert_equal hash, @cache.layers.last.read_multi(:a, :b, :c)
  end

  def test_read_multi_miss_on_layer_1_and_read_multi_hit_on_layer_2_without_side_effects
    hash = {a: 1, b: 2, c: 3}
    @cache.write_multi(hash)
    sleep 1
    assert_equal hash, @cache.read_multi(:a, :b, :c) # layer-1 miss, layer-2 hit
    assert_equal 0, @cache.layers.first.read_multi(:a, :b, :c).size # layer-1 miss
    assert_equal hash, @cache.layers.last.read_multi(:a, :b, :c) # layer-2 hit
  end

  def test_fetch
    @cache.fetch(:test) { "value" }
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
  end

  def test_fetch_rewrites_to_layer_1_cache_on_layer_1_cache_miss
    @cache.write(:test, "value")
    sleep 1
    assert_nil @cache.layers.first.read(:test) # layer-1 miss
    assert_equal "value", @cache.layers.last.read(:test) # layer-2 hit
    @cache.fetch(:test) { "value" } # rewrites layer-1
    assert_equal "value", @cache.layers.first.read(:test) # layer-1 hit
  end

  def test_fetch_multi_rewrites_to_layer_1_cache_on_layer_1_cache_miss
    expected = {a: "aa", b: "bb", c: "cc"}
    @cache.write_multi(expected)
    sleep 1
    assert_equal 0, @cache.layers.first.read_multi(:a, :b, :c).size # layer-1 miss
    assert_equal expected, @cache.layers.last.read_multi(:a, :b, :c) # layer-2 hit
    @cache.fetch_multi(:a, :b, :c) { |key| key * 2 } # rewrites layer-1
    assert_equal expected, @cache.layers.first.read_multi(:a, :b, :c) # layer-1 hit
  end

  def test_delete
    @cache.write(:test, "value")
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
    @cache.delete(:test)
    assert_nil @cache.read(:test)
    assert_nil @cache.layers.first.read(:test)
    assert_nil @cache.layers.last.read(:test)
  end

  def test_applies_expires_in_when_value_is_less_than_caches_configured_expires_in
    @cache.write(:test, "value", expires_in: 0.1.seconds)
    assert_equal "value", @cache.read(:test)
    assert_equal "value", @cache.layers.first.read(:test)
    assert_equal "value", @cache.layers.last.read(:test)
    sleep 0.1
    assert_nil @cache.read(:test)
    assert_nil @cache.layers.first.read(:test)
    assert_nil @cache.layers.last.read(:test)
  end

  def test_applies_expires_at_when_computed_expires_in_is_less_than_stores_configured_expires_in
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
