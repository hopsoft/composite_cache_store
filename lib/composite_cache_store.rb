# frozen_string_literal: true

require "active_support/cache"
require_relative "composite_cache_store/version"

class CompositeCacheStore
  DEFAULT_LAYER_1_OPTIONS = {
    expires_in: 5.minutes,
    size: 16.megabytes
  }

  DEFAULT_LAYER_2_OPTIONS = {
    expires_in: 1.day,
    size: 32.megabytes
  }

  attr_reader :layers
  delegate_missing_to :"layers.last"

  # Returns a new CompositeCacheStore instance
  def initialize(*layers)
    if layers.blank?
      layers << ActiveSupport::Cache::MemoryStore.new(DEFAULT_LAYER_1_OPTIONS)
      layers << ActiveSupport::Cache::MemoryStore.new(DEFAULT_LAYER_2_OPTIONS)
    end

    layers.freeze
    @layers = layers
  end

  def cleanup(...)
    layers.each { |store| store.cleanup(...) }
  end

  def clear(...)
    layers.each { |store| store.clear(...) }
  end

  def decrement(...)
    layers.each { |store| store.decrement(...) }
  end

  def delete(...)
    layers.each { |store| store.delete(...) }
  end

  def delete_matched(...)
    layers.each { |store| store.delete_matched(...) }
  end

  def delete_multi(...)
    layers.each { |store| store.delete_multi(...) }
  end

  def exist?(...)
    layers.each do |store|
      return true if store.exist?(...)
    end
    false
  end

  def fetch(*args, &block)
    f = ->(store) do
      return store.fetch(*args, &block) if store == layers.last
      store.fetch(*args) { f.call(layers[layers.index(store) + 1]) }
    end
    f.call(layers.first)
  end

  def fetch_multi(*args, &block)
    fm = ->(store) do
      return store.fetch_multi(*args, &block) if store == layers.last
      store.fetch_multi(*args) { fm.call(layers[layers.index(store) + 1]) }
    end
    fm.call(layers.first)
  end

  def increment(...)
    layers.each { |store| store.increment(...) }
  end

  def mute
    m = ->(store) do
      return store.mute { yield } if store == layers.last
      store.mute { m.call(layers[layers.index(store) + 1]) }
    end
    m.call(layers.first)
  end

  def read(*args)
    r = ->(store) do
      return store.read(*args) if store == layers.last
      store.fetch(*args) { r.call(layers[layers.index(store) + 1]) }
    end
    r.call(layers.first)
  end

  def read_multi(...)
    layers.each do |store|
      result = store.read_multi(...)
      return result if result.present?
    end
    nil
  end

  def silence!
    layers.each { |store| store.silence! }
  end

  # Only applies expiration options to the outermost cache
  # Inner caches use their global expiration options
  def write(name, value, options = nil)
    options ||= {}
    layers.each do |store|
      if store == layers.last
        store.write(name, value, options)
      else
        store.write(name, value, options.except(:expires_in, :expires_at))
      end
    end
  end

  # Only applies expiration options to the outermost cache
  # Inner caches use their global expiration options
  def write_multi(hash, options = nil)
    options ||= {}
    layers.each do |store|
      if store == layers.last
        store.write_multi(hash, options)
      else
        store.write_multi(hash, options.except(:expires_in, :expires_at))
      end
    end
  end
end
