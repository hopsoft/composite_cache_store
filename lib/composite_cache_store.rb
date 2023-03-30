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

  def cleanup(...)
    layers.map { |layer| layer.cleanup(...) }.last
  end

  def clear(...)
    layers.map { |layer| layer.clear(...) }.last
  end

  def increment(name, amount = 1, options = nil)
    provisional_layers.each { |layer| layer.delete(name, options) }
    layers.last.increment(name, amount, options)
  end

  def decrement(name, amount = 1, options = nil)
    provisional_layers.each { |layer| layer.delete(name, options) }
    layers.last.decrement(name, amount, options)
  end

  def delete(...)
    layers.map { |layer| layer.delete(...) }.last
  end

  def delete_matched(...)
    layers.map { |layer| layer.delete_matched(...) }.last
  end

  def delete_multi(...)
    layers.map { |layer| layer.delete_multi(...) }.last
  end

  def exist?(...)
    layers.any? { |layer| layer.exist?(...) }
  end

  def fetch(name, options = nil, &block)
    options ||= {}

    if options[:force]
      raise ArgumentError, "Missing block: Calling `Cache#fetch` with `force: true` requires a block." unless block
      value = block&.call(name)
      layers.each { |layer| layer.write(name, options) }
      return value
    end

    read(name, options) do |value, warm_layer, cold_layers|
      value ||= block&.call(name) unless warm_layer
      cold_layers.each do |layer|
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

    read_multi(*names) do |value, warm_layer, cold_layers|
      missing_keys = keys - value.keys
      missing_keys.each { |key| value[key] = block&.call(key) }

      cold_layers.each do |layer|
        value.compact! if options[:skip_nil]
        layer.write_multi(value, options)
      end

      return keys.each_with_object({}) { |key, memo| memo[key] = value[key] }
    end
  end

  def mute
    layers.map { |layer| layer.mute { yield } }.last
  end

  def read(name, options = nil)
    warm_layer = nil
    cold_layers = []
    value = nil

    layers.each do |layer|
      value = layer.read(name, options)
      warm_layer = layer if !value.nil? || layer.exist?(name, options)
      break if warm_layer
      cold_layers << layer
    end

    yield(value, warm_layer, cold_layers) if block_given?
    value
  end

  def read_multi(*names)
    keys = names.dup
    keys.extract_options!

    warm_layer = nil
    cold_layers = []
    value = {}

    layers.each do |layer|
      hash = layer.read_multi(*names)
      value.merge!(hash) if hash.size > value.size
      warm_layer = layer if hash.size == keys.size
      break if warm_layer
      cold_layers << layer
    end

    yield(value, warm_layer, cold_layers) if block_given?
    value
  end

  def silence!
    layers.map { |layer| layer.silence! }.last
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
