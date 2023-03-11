# frozen_string_literal: true

require_relative "test_helper"

class TurboBoost::Cache::StoreTest < ActiveSupport::TestCase
  setup do
    @logger = Logger.new("/dev/null") # used for Standard/Rubocop shenanigans

    # NOTE: The inner cache store would normally use a shared persistence service like
    #       Redis via ActiveSupport::Cache::RedisCacheStore
    #
    #       In a Rails app you might use Rails.cache as the inner cache store
    @store = TurboBoost::Cache::Store.new(
      expires_in: 1.second,
      size: 8.megabytes,
      inner: ActiveSupport::Cache::MemoryStore.new(
        expires_in: 1.minute,
        size: 64.megabytes
      )
    )
  end

  test "default instantation" do
    store = TurboBoost::Cache::Store.new
    assert store.outer.is_a?(ActiveSupport::Cache::MemoryStore)
    assert store.inner.is_a?(ActiveSupport::Cache::NullStore)
  end

  test "custom instantation" do
    assert_equal 1.minute, @store.inner.options[:expires_in]
    assert_equal 64.megabytes, @store.inner.options[:size]
    assert_equal 1.second, @store.outer.options[:expires_in]
    assert_equal 8.megabytes, @store.outer.options[:size]
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
