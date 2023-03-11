# frozen_string_literal: true

require "active_support/cache"
require_relative "composite_cache_store/version"

class CompositeCacheStore
  DEFAULT_OUTER_OPTIONS = {
    expires_in: 5.minutes,
    size: 16.megabytes
  }

  DEFAULT_INNER_OPTIONS = {
    expires_in: 1.day,
    size: 32.megabytes
  }

  attr_reader :outer_cache_store, :inner_cache_store

  alias_method :outer, :outer_cache_store
  alias_method :inner, :inner_cache_store

  # Returns a new CompositeCacheStore instance
  # - inner_cache_store: An ActiveSupport::Cache::Store instance to use for the inner cache store (typically remote)
  # - outer_cache_store: An ActiveSupport::Cache::Store instance to use for the outer cache store (typically local)
  def initialize(options = {})
    options ||= {}

    @inner_cache_store = options[:inner_cache_store]
    @inner_cache_store = ActiveSupport::Cache::MemoryStore.new(DEFAULT_INNER_OPTIONS) unless inner.is_a?(ActiveSupport::Cache::Store)

    @outer_cache_store = options[:outer_cache_store]
    @outer_cache_store = ActiveSupport::Cache::MemoryStore.new(DEFAULT_OUTER_OPTIONS) unless outer.is_a?(ActiveSupport::Cache::Store)
  end

  def cleanup(...)
    outer.cleanup(...)
    inner.cleanup(...)
  end

  def clear(...)
    outer.clear(...)
    inner.clear(...)
  end

  def decrement(...)
    outer.decrement(...)
    inner.decrement(...)
  end

  def delete(...)
    outer.delete(...)
    inner.delete(...)
  end

  def delete_matched(...)
    outer.delete_matched(...)
    inner.delete_matched(...)
  end

  def delete_multi(...)
    outer.delete_multi(...)
    inner.delete_multi(...)
  end

  def exist?(...)
    outer.exist?(...) || inner.exist?(...)
  end

  def fetch(*args, &block)
    outer.fetch(*args) do
      inner.fetch(*args, &block)
    end
  end

  def fetch_multi(*args, &block)
    outer.fetch_multi(*args) do
      inner.fetch_multi(*args, &block)
    end
  end

  # write
  def increment(...)
    outer.increment(...)
    inner.increment(...)
  end

  def mute
    outer.mute do
      inner.mute do
        yield
      end
    end
  end

  def read(*args)
    outer.fetch(*args) do
      inner.read(*args)
    end
  end

  def read_multi(...)
    result = outer.read_multi(...)
    result = inner.read_multi(...) if result.blank?
    result
  end

  def silence!
    outer.silence!
    inner.silence!
  end

  def write(name, value, options = nil)
    options ||= {}
    outer.write(name, value, options.except(:expires_in)) # ? accept expires_in if less than outer.config[:expires_in] ?
    inner.write(name, value, options)
  end

  def write_multi(hash, options = nil)
    options ||= {}
    outer.write_multi(hash, options.except(:expires_in)) # ? accept expires_in if less than outer.config[:expires_in] ?
    inner.write_multi(hash, options)
  end
end
