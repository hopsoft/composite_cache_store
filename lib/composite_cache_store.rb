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
    value = nil

    unless options&.dig(:force) || options&.dig(:race_condition_ttl)
      value = read(name, options)
      return value if value
    end

    layers.each do |layer|
      if value
        layer.write name, value, options
      else
        value = layer.fetch(name, options, &block)
      end
    end

    value
  end

  def fetch_multi(*names, &block)
    options = names.dup.extract_options!
    value = {}

    unless options[:force] || options[:race_condition_ttl]
      value = read_multi(*names)
      return value if value.compact.size == names.size
    end

    value = {}
    layers.each do |layer|
      if value
        layer.write_multi value, options
      else
        value = layer.fetch_multi(*names, &block)
      end
    end

    # names.each_with_object({}) { |name, memo| memo[name] = nil }
    value
  end

  def mute
    layers.each { |layer| layer.mute { yield } }
  end

  def read(...)
    value = nil
    layers.find { |layer| value = layer.read(...) }
    value
  end

  def read_multi(*names)
    value = {}
    layers.each do |layer|
      value = layer.read_multi(*names)
      return value if value.size == names.size
    end
    value
  end

  def silence!
    layers.each { |layer| layer.silence! }
  end

  def write(name, value, options = nil)
    return_value = false
    layers.each do |layer|
      return_value = layer.write(name, value, permitted_options(layer, options))
    end
    return_value
  end

  def write_multi(hash, options = nil)
    layers.each do |layer|
      layer.write_multi hash, permitted_options(layer, options)
    end
  end

  private

  def provisional_layers
    layers.take layers.size - 1
  end

  def permitted_options(layer, options = {})
    options = {} unless options.is_a?(Hash)
    return options if options.blank?
    return options if keep_expiration?(layer, options)
    options.except(:expires_in, :expires_at)
  end

  def keep_expiration?(layer, options = {})
    return true if layer == layers.last
    return true unless layer.options[:expires_in]

    expires_in = options[:expires_in]
    if options[:expires_at]
      expires_in ||= options[:expires_at] - Time.current
      options.delete(:expires_at)
    end
    return false unless expires_in

    expires_in < layer.options[:expires_in]
  end
end
