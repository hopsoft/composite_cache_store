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

    raise ArgumentError.new("A layered cache requires more than 1 layer!") unless layers.size > 1

    unless layers.all? { |layer| layer.is_a? ActiveSupport::Cache::Store }
      raise ArgumentError.new("All layers must be instances of ActiveSupport::Cache::Store!")
    end

    @layers = layers.freeze
    @logger = options[:logger]
    @options = options
  end

  def read(name, options = nil)
    value = nil
    warm_layer = layers.find { |layer| layer_read?(layer, name, options) { |val| value = val } }
    yield(value, warm_layer) if block_given?
    value
  end

  def read_multi(*names)
    value = {}
    warm_layer = layers.find { |layer| layer_read_multi?(layer, *names) { |val| value.merge!(val) } }
    yield(value, warm_layer) if block_given?
    value
  end

  def fetch(name, options = nil, &block)
    options ||= {}

    if options[:force]
      raise ArgumentError, "Missing block: Calling `Cache#fetch` with `force: true` requires a block." unless block
      value = block&.call(name)
      layers.each { |layer| layer.write(name, value, options) }
      return value
    end

    read(name, options) do |value, warm_layer|
      value ||= block&.call(name) unless warm_layer

      layers.each do |layer|
        break if layer == warm_layer
        layer.write(name, value, options) unless value.nil? && options[:skip_nil]
      end

      return value
    end
  end

  def fetch_multi(*names, &block)
    raise ArgumentError, "Missing block: `Cache#fetch_multi` requires a block." unless block

    keys = names.dup
    options = keys.extract_options!

    if options[:force]
      value = keys.each_with_object({}) { |key, memo| memo[key] = block&.call(key) }
      layers.each { |layer| layer.write_multi(value, options) }
      return value
    end

    read_multi(*names) do |value, warm_layer|
      unless warm_layer
        missing_keys = keys - value.keys
        missing_keys.each { |key| value[key] = block&.call(key) }
      end

      value.compact! if options[:skip_nil]

      layers.each do |layer|
        break if layer == warm_layer
        layer.write_multi(value, options)
      end

      # return ordered hash value
      return keys.each_with_object({}) { |key, memo| memo[key] = value[key] }
    end
  end

  def write(name, value, options = nil)
    layers.map { |layer| layer.write(name, value, options) }.last
  end

  def write_multi(hash, options = nil)
    layers.map { |layer| layer.write_multi(hash, options) }.last
  end

  def delete(...)
    layers.map { |layer| layer.delete(...) }.last
  end

  def delete_multi(...)
    layers.map { |layer| layer.delete_multi(...) }.last
  end

  def delete_matched(...)
    layers.map { |layer| layer.delete_matched(...) }.last
  end

  def increment(name, amount = 1, options = nil)
    provisional_layers.each { |layer| layer.delete(name, options) }
    layers.last.increment(name, amount, options)
  end

  def decrement(name, amount = 1, options = nil)
    provisional_layers.each { |layer| layer.delete(name, options) }
    layers.last.decrement(name, amount, options)
  end

  def cleanup(...)
    layers.map { |layer| layer.cleanup(...) }.last
  end

  def clear(...)
    layers.map { |layer| layer.clear(...) }.last
  end

  def exist?(...)
    layers.any? { |layer| layer.exist?(...) }
  end

  def mute
    layers.map { |layer| layer.mute { yield } }.last
  end

  def silence!
    layers.map { |layer| layer.silence! }.last
  end

  private

  def provisional_layers
    layers.take layers.size - 1
  end

  def layer_read?(layer, name, options)
    if layer.respond_to?(:with_local_cache)
      layer.with_local_cache do
        value = layer.read(name, options)
        yield value
        value || layer.exist?(name, options)
      end
    else
      value = layer.read(name, options)
      yield value
      value || layer.exist?(name, options)
    end
  end

  def layer_read_multi?(layer, *names)
    keys = names.dup
    keys.extract_options!

    value = if layer.respond_to?(:with_local_cache)
      layer.with_local_cache { layer.read_multi(*names) }
    else
      layer.read_multi(*names)
    end

    yield value
    value.size == keys.size
  end
end
