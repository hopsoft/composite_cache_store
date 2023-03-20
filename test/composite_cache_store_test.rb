# frozen_string_literal: true

require_relative "test_helper"

class CompositeCacheStoreTest < MethodCallAssertionsTest
  include CacheStoreBehavior

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

  tests_to_rewrite = %i[
    test_cache_hit_instrumentation
    test_cache_miss_instrumentation
    test_expires_at
    test_expires_in_and_expires_at
    test_fetch_multi_with_objects
    test_fetch_with_cache_miss
    test_fetch_with_dynamic_options
    test_fetch_with_forced_cache_miss
    test_format_of_expanded_key_for_single_instance
    test_format_of_expanded_key_for_single_instance_in_array
    test_incompressible_data
    test_large_object_with_compress_false
    test_large_object_with_compress_true
    test_large_object_with_high_compress_threshold
    test_large_string_with_compress_false
    test_large_string_with_compress_true
    test_large_string_with_high_compress_threshold
    test_nil_with_compress_false
    test_nil_with_compress_low_compress_threshold
    test_nil_with_compress_true
    test_nil_with_default_compression_settings
    test_race_condition_protection
    test_race_condition_protection_skipped_if_not_defined
    test_small_object_with_compress_false
    test_small_object_with_compress_true
    test_small_object_with_default_compression_settings
    test_small_object_with_low_compress_threshold
    test_small_string_with_compress_false
    test_small_string_with_compress_true
    test_small_string_with_default_compression_settings
    test_small_string_with_low_compress_threshold
  ]

  tests_to_rewrite.each do |test|
    define_method test do
      skip "TODO: Rewrite or explain why test is not-applicable for stores that don't subclass ActiveSupport::Cache::Store"
    end
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

  # test "write and read" do
  #   @store.write(:test, "value")
  #   assert_equal "value", @store.read(:test)
  #   assert_equal "value", @store.layers.first.read(:test)
  #   assert_equal "value", @store.layers.last.read(:test)
  # end

  # test "read rewrites to layer-1 cache on layer-1 cache miss" do
  #   @store.write(:test, "value")
  #   sleep 1
  #   assert_nil @store.layers.first.read(:test) # layer-1 miss
  #   assert_equal "value", @store.layers.last.read(:test) # layer-2 hit
  #   assert_equal "value", @store.read(:test) # rewrites to layer-1
  #   assert_equal "value", @store.layers.first.read(:test) # layer-1 hit
  # end

  # test "write_multi and read_multi" do
  #   hash = {a: 1, b: 2, c: 3}
  #   @store.write_multi(hash)
  #   assert_equal hash, @store.read_multi(:a, :b, :c)
  #   assert_equal hash, @store.layers.first.read_multi(:a, :b, :c)
  #   assert_equal hash, @store.layers.last.read_multi(:a, :b, :c)
  # end

  # test "read_multi rewrites to layer-1 cache on layer-1 cache miss" do
  #   hash = {a: 1, b: 2, c: 3}
  #   @store.write_multi(hash)
  #   sleep 1
  #   assert @store.layers.first.read_multi(:a, :b, :c).blank?
  #   assert_equal hash, @store.layers.last.read_multi(:a, :b, :c)
  #   assert_equal hash, @store.read_multi(:a, :b, :c)
  #   assert_equal hash, @store.layers.first.read_multi(:a, :b, :c)
  # end

  # test "fetch" do
  #   @store.fetch(:test) do
  #     "value"
  #   end
  #   assert_equal "value", @store.read(:test)
  #   assert_equal "value", @store.layers.first.read(:test)
  #   assert_equal "value", @store.layers.last.read(:test)
  # end

  # test "fetch rewrites to layer-1 cache on layer-1 cache miss" do
  #   @store.write(:test, "value")
  #   sleep 1
  #   assert_nil @store.layers.first.read(:test) # layer-1 miss
  #   assert_equal "value", @store.layers.last.read(:test) # layer-2 hit
  #   @store.fetch(:test) do # rewrites layer-1
  #     "value"
  #   end
  #   assert_equal "value", @store.layers.first.read(:test) # layer-1 hit
  # end

  # test "delete " do
  #   @store.write(:test, "value")
  #   assert_equal "value", @store.read(:test)
  #   assert_equal "value", @store.layers.first.read(:test)
  #   assert_equal "value", @store.layers.last.read(:test)
  #   @store.delete(:test)
  #   assert_nil @store.read(:test)
  #   assert_nil @store.layers.first.read(:test)
  #   assert_nil @store.layers.last.read(:test)
  # end

  # test "applies expires_in when value is less than store's configured expires_in" do
  #   @store.write(:test, "value", expires_in: 0.1.seconds)
  #   assert_equal "value", @store.read(:test)
  #   assert_equal "value", @store.layers.first.read(:test)
  #   assert_equal "value", @store.layers.last.read(:test)
  #   sleep 0.1
  #   assert_nil @store.read(:test)
  #   assert_nil @store.layers.first.read(:test)
  #   assert_nil @store.layers.last.read(:test)
  # end

  # test "applies expires_at when computed expires_in is less than store's configured expires_in" do
  #   @store.write(:test, "value", expires_at: 0.1.second.from_now)
  #   assert_equal "value", @store.read(:test)
  #   assert_equal "value", @store.layers.first.read(:test)
  #   assert_equal "value", @store.layers.last.read(:test)
  #   sleep 0.1
  #   assert_nil @store.read(:test)
  #   assert_nil @store.layers.first.read(:test)
  #   assert_nil @store.layers.last.read(:test)
  # end
end
