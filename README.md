# CompositeCacheStore

### A composite cache store comprised of 2 ActiveSupport::Cache::Store instances

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Why a composite cache?](#why-a-composite-cache)
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
__A composite (or layered) cache can mitigate these risks.__
It can also alleviate traffic and backpressure on the persistence service.

Consider a composite cache that wraps a remote Redis-backed store with an local in-memory store.
When both caches are warm, a read hit on the local in-memory store will return instantly, avoiding the overhead
of inter-process communication (IPC) and/or network traffic _(with its attendant data marshaling and socket/wire noise)._

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
  @store ||= CompositeCacheStore.new(
    inner_cache_store: Rails.cache, # use whatever makes sense for your app as the remote inner-cache
    outer_cache_store: ActiveSupport::Cache::MemoryStore.new( # employs an LRU eviction policy
      expires_in: 15.minutes, # constrain entry lifetime so the local outer-cache doesn't drift out of sync
      size: 32.megabytes # constrain max memory used by the local outer-cache
    )
  )
end
```

## Usage

A composite cache is ideal for mitigating hot spot latency in frequently invoked areas of the codebase.

```ruby
# method that's invoked frequently by multiple processes
def hotspot
  # NOTE: the expires_in option is only applied to the remote inner-cache
  #       the local outer-cache uses its globally configured expiration policy
  Rails.composite_cache.fetch("example/slow/operation", expires_in: 12.hours) do
    # a slow operation
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
