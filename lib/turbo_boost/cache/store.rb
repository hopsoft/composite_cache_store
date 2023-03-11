# frozen_string_literal: true

require "active_support/cache"

module TurboBoost::Cache
  class Store
    attr_reader :outer, :inner

    # Options (same as ActiveSupport::Cache::MemoryStore)
    # - inner: An ActiveSupport::Cache::Store instance to use for the inner cache store
    def initialize(options = {})
      options ||= {}
      @inner = options[:inner] || ActiveSupport::Cache::NullStore.new
      options.delete :inner
      @outer = ActiveSupport::Cache::MemoryStore.new(options)
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

    # TODO: optimize this?
    def read_multi(...)
      inner.read_multi(...)
    end

    def silence!
      outer.silence!
      inner.silence!
    end

    def write(...)
      outer.write(...)
      inner.write(...)
    end

    def write_multi(...)
      outer.write_multi(...)
      inner.write_multi(...)
    end
  end
end
