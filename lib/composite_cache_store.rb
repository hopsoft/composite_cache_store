# frozen_string_literal: true

require "active_support/all"
require_relative "composite_cache_store/version"

class CompositeCacheStore < ActiveSupport::Cache::Store
  DEFAULT_LAYER_1_OPTIONS = {
    expires_in: 5.minutes,
    size: 16.megabytes
  }

  DEFAULT_LAYER_2_OPTIONS = {
    expires_in: 1.day,
    size: 32.megabytes
  }

  attr_reader :layers

  # Returns a new CompositeCacheStore instance
  def initialize(options = nil)
    layers = options.delete(:layers)

    if layers.blank?
      layers << ActiveSupport::Cache::MemoryStore.new(DEFAULT_LAYER_1_OPTIONS)
      layers << ActiveSupport::Cache::MemoryStore.new(DEFAULT_LAYER_2_OPTIONS)
    end

    message = "All layers must be instances of ActiveSupport::Cache::Store"
    layers.each do |layer|
      raise ArgumentError.new(message) unless layer.is_a?(ActiveSupport::Cache::Store)
    end

    layers.freeze
    @layers = layers
    super(options)
  end

  def cleanup(...)
    layers.each { |store| store.cleanup(...) }
  end

  def clear(...)
    layers.each { |store| store.clear(...) }
  end

  def decrement(...)
    layers.map { |store| store.decrement(...) }.max
  end

  def delete_matched(...)
    layers.each { |store| store.delete_matched(...) }
  end

  def exist?(...)
    layers.each do |store|
      return true if store.exist?(...)
    end
    false
  end

  def increment(...)
    layers.map { |store| store.increment(...) }.min
  end

  def mute
    m = ->(store) do
      return store.mute { yield } if store == layers.last
      store.mute { m.call(layers[layers.index(store) + 1]) }
    end
    m.call(layers.first)
  end

  def silence!
    layers.each { |store| store.silence! }
  end

  private

  def read_entry(key, **options)
    layers.each do |store|
      entry = store.send "read_entry", key, **options
      return entry unless entry.nil?
    end

    nil
  end

  def write_entry(key, entry, **options)
    layers.each do |store|
      store.send "write_entry", key, entry, **permitted_options(store, options)
    end
  end

  def delete_entry(key, **options)
    layers.all? { |store| store.send "delete_entry", key, **options }
  end

  def permitted_options(store, options = {})
    return options if options.blank?
    return options if keep_expiration?(store, options)
    options.except(:expires_in, :expires_at)
  end

  def keep_expiration?(store, options = {})
    return true if store == layers.last
    return true unless store.options[:expires_in]

    expires_in = options[:expires_in]
    expires_in ||= Time.current - options[:expires_at] if options[:expires_at]
    return false unless expires_in

    expires_in < store.options[:expires_in]
  end
end
