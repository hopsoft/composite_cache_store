# frozen_string_literal: true

require "active_support/all"
require_relative "composite_cache_store/version"

class CompositeCacheStore
  attr_reader :options, :layers
  attr_accessor :logger

  # Returns a new CompositeCacheStore instance
  def initialize(options = {})
    options = options.dup || {}
    layers = options.delete(:layers) || []
    if layers.blank?
      layers << ActiveSupport::Cache::MemoryStore.new({expires_in: 5.minutes, size: 16.megabytes}.merge(options))
      layers << ActiveSupport::Cache::MemoryStore.new({expires_in: 1.day, size: 32.megabytes}.merge(options))
    end

    stores = layers.select { |layer| layer.is_a? ActiveSupport::Cache::Store }
    raise ArgumentError.new("All layers must be instances of ActiveSupport::Cache::Store") unless stores.size == layers.size

    @layers = layers.freeze
    @logger = options[:logger]
    @options = options
  end

  def cleanup(...)
    layers.each { |layer| layer.cleanup(...) }
  end

  def clear(...)
    layers.each { |layer| layer.clear(...) }
  end

  def increment(name, amount = 1, options = nil)
    value = layers.last.increment(name, amount, options)
    provisional_layers.each { |layer| layer.write(name, value, options) }
    value
  end

  def decrement(name, amount = 1, options = nil)
    value = layers.last.decrement(name, amount, options)
    provisional_layers.each { |layer| layer.write(name, value, options) }
    value
  end

  def delete(...)
    layers.each { |layer| layer.delete(...) }
  end

  def delete_matched(...)
    layers.each { |layer| layer.delete_matched(...) }
  end

  def delete_multi(...)
    layers.map { |layer| layer.delete_multi(...) }.last
  end

  def exist?(...)
    layers.each do |layer|
      return true if layer.exist?(...)
    end
    false
  end

  def fetch(name, options = nil, &block)
    value = read(name, options) unless options&.dig(:force) || options&.dig(:race_condition_ttl)
    return value if value

    layers.each do |layer|
      if value
        layer.write name, value, options
      else
        value = layer.fetch(name, options, &block)
      end
    end

    value
  end

  def fetch_multi(*args, &block)
    names = args.dup
    options = names.extract_options!

    value = read_multi(*names) unless options[:force] || options[:race_condition_ttl]
    value ||= {}
    return value if value.compact.size == names.size

    value = {}
    layers.each do |layer|
      if value.compact.size == names.size
        layer.write_multi value, options
      else
        value = layer.fetch_multi(*args, &block)
      end
    end
    value
  end

  def mute
    layers.each { |layer| layer.mute { yield } }
  end

  def read(name, options = nil)
    value = nil
    cache_miss_layers = []
    layers.find do |layer|
      value = layer.read(name, options)
      cache_miss_layers << layer unless value
      value
    end
    cache_miss_layers.each { |layer| layer.write(name, value, options) } if value
    value
  end

  def read_multi(*names)
    value = {}
    cache_miss_layers = []
    layers.find do |layer|
      value = layer.read_multi(*names)
      cache_miss_layers << layer unless value.size == names.size
      value.size == names.size
    end
    cache_miss_layers.each { |layer| layer.write_multi(value, options) } if value.size == names.size
    value
  end

  def silence!
    layers.each { |layer| layer.silence! }
  end

  def write(name, value, options = nil)
    layers.map { |layer| layer.write(name, value, options) }.last
  end

  def write_multi(hash, options = nil)
    layers.map { |layer| layer.write_multi(hash, options) }.last
  end

  private

  def provisional_layers
    layers.take layers.size - 1
  end
end
