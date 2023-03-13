# CompositeCacheStore

### A composite cache store comprised of 2 ActiveSupport::Cache::Store instances

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Why a composite cache?](#why-a-composite-cache)
  - [Sponsors](#sponsors)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Setup](#setup)
    - [Ruby on Rails](#ruby-on-rails)
  - [Usage](#usage)
  - [License](#license)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## Why a composite cache?

Most web applications implement some form of caching mechanics to improve performance.
Sufficiently large applications often employ a persistence service to back the cache.
_(Redis, Memcache, etc.)_ These services make it possible to use a shared cache between multiple machines/processes.

While these services are robust and performant, they can also be a source of latency and are potential bottlenecks.
__A composite (or layered) cache can mitigate these risks__
by reducing traffic and backpressure on the persistence service.

Consider a composite cache that wraps a remote Redis-backed "outer cache" with a local in-memory "inner cache".
When both caches are warm, a read hit on the local in-memory cache returns instantly and avoids the overhead of
inter-process communication (IPC) and/or network traffic _(with its attendant data marshaling and socket/wire noise)_
associated with accessing the remote Redis-backed cache.

To summarize: __Reads prioritize the inner cache and fall back to the outer cache.__

## Sponsors

<p align="center">
  <em>Proudly sponsored by</em>
</p>
<p align="center">
  <a href="https://www.clickfunnels.com?utm_source=hopsoft&utm_medium=open-source&utm_campaign=composite_cache_store">
    <img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" />
  </a>
</p>

## Dependencies

- [ActiveSupport `>= 6.0`](https://github.com/rails/rails/tree/main/activesupport)

## Installation

```sh
bundle add "composite_cache_store"
```

## Setup

### Ruby on Rails

```ruby
# config/environments/production.rb
module Example
  class Application < Rails::Application
    config.cache_store = :redis_cache_store, { url: "redis://example.com:6379/1" }
  end
end
```

```ruby
# config/initializers/composite_cache_store.rb
def Rails.composite_cache
  @composite_cache ||= CompositeCacheStore.new(
    # Layer 1 cache (inner) - employs an LRU eviction policy
    ActiveSupport::Cache::MemoryStore.new(
      expires_in: 15.minutes, # constrain entry lifetime so the local cache doesn't drift out of sync
      size: 32.megabytes # constrain max memory used by the local cache
    ),

    # Layer 2 cache (outer)
    Rails.cache, # use whatever makes sense for your app

    # additional layers are optional
  )
end
```

## Usage

A composite cache is ideal for mitigating hot spot latency in frequently invoked areas of the codebase.

```ruby
# method that's invoked frequently by multiple processes
def hotspot
  # NOTE: expiration options are only applied to the outermost cache
  #       inner caches use their globally configured expiration policy
  Rails.composite_cache.fetch("example/slow/operation", expires_in: 12.hours) do
    # a slow operation
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
