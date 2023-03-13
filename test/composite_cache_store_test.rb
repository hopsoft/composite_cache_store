# frozen_string_literal: true

require_relative "test_helper"

class CompositeCacheStoreTest < ActiveSupport::TestCase
  setup do
    @logger = Logger.new("/dev/null") # used for Standard/Rubocop shenanigans

    @store = CompositeCacheStore.new(
      ActiveSupport::Cache::MemoryStore.new(expires_in: 1.second, size: 8.megabytes),
      ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute, size: 64.megabytes)
    )
  end

  test "default instantation" do
    store = CompositeCacheStore.new

    expected = {expires_in: 5.minutes, size: 16.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.layers.first.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.layers.first.options

    expected = {expires_in: 1.day, size: 32.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert store.layers.last.is_a?(ActiveSupport::Cache::MemoryStore)
    assert_equal expected, store.layers.last.options
  end

  test "custom instantation" do
    expected = {expires_in: 1.second, size: 8.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @store.layers.first.options

    expected = {expires_in: 1.minute, size: 64.megabytes, compress: false, compress_threshold: 1.kilobyte}
    assert_equal expected, @store.layers.last.options
  end

  test "write and read" do
    @store.write(:test, "value")
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.layers.first.read(:test)
    assert_equal "value", @store.layers.last.read(:test)
  end

  test "read rewrites to outer cache on outer cache miss" do
    @store.write(:test, "value")
    sleep 1
    assert_nil @store.layers.first.read(:test) # layer 1 miss
    assert_equal "value", @store.layers.last.read(:test) # layer 2 hit
    assert_equal "value", @store.read(:test) # rewrites to layer 1
    assert_equal "value", @store.layers.first.read(:test) # layer 1 hit
  end

  test "fetch" do
    @store.fetch(:test) do
      @logger.debug "Prevent Standard/Rubocop from jacking up the fetch block ¯\\_(ツ)_/¯"
      "value"
    end
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.layers.first.read(:test)
    assert_equal "value", @store.layers.last.read(:test)
  end

  test "fetch rewrites to outer cache on outer cache miss" do
    @store.write(:test, "value")
    sleep 1
    assert_nil @store.layers.first.read(:test) # layer 1 miss
    assert_equal "value", @store.layers.last.read(:test) # layer 2 hit
    @store.fetch(:test) do # rewrites layer 1
      @logger.debug "Prevent Standard/Rubocop from jacking up the fetch block ¯\\_(ツ)_/¯"
      "value"
    end
    assert_equal "value", @store.layers.first.read(:test) # layer 1 hit
  end

  test "delete" do
    @store.write(:test, "value")
    assert_equal "value", @store.read(:test)
    assert_equal "value", @store.layers.first.read(:test)
    assert_equal "value", @store.layers.last.read(:test)
    @store.delete(:test)
    assert_nil @store.read(:test)
    assert_nil @store.layers.first.read(:test)
    assert_nil @store.layers.last.read(:test)
  end
end
