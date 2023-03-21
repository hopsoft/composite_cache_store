<p align="center">
  <h1 align="center">CompositeCacheStore 🚀</h1>
  <p align="center">
    <a href="http://blog.codinghorror.com/the-best-code-is-no-code-at-all/">
      <img alt="Lines of Code" src="https://img.shields.io/badge/loc-119-47d299.svg" />
    </a>
    <a href="https://codeclimate.com/github/hopsoft/composite_cache_store/maintainability">
      <img src="https://api.codeclimate.com/v1/badges/80bcd3acced072534a3a/maintainability" />
    </a>
    <a href="https://rubygems.org/gems/composite_cache_store">
      <img alt="GEM Version" src="https://img.shields.io/gem/v/composite_cache_store?color=168AFE&include_prereleases&logo=ruby&logoColor=FE1616">
    </a>
    <a href="https://rubygems.org/gems/composite_cache_store">
      <img alt="GEM Downloads" src="https://img.shields.io/gem/dt/composite_cache_store?color=168AFE&logo=ruby&logoColor=FE1616">
    </a>
    <a href="https://github.com/testdouble/standard">
      <img alt="Ruby Style" src="https://img.shields.io/badge/style-standard-168AFE?logo=ruby&logoColor=FE1616" />
    </a>
    <a href="https://github.com/hopsoft/composite_cache_store/actions/workflows/tests.yml">
      <img alt="Tests" src="https://github.com/hopsoft/composite_cache_store/actions/workflows/tests.yml/badge.svg" />
    </a>
    <a href="https://github.com/sponsors/hopsoft">
      <img alt="Sponsors" src="https://img.shields.io/github/sponsors/hopsoft?color=eb4aaa&logo=GitHub%20Sponsors" />
    </a>
    <br>
    <a href="https://ruby.social/@hopsoft">
      <img alt="Ruby.Social Follow" src="https://img.shields.io/mastodon/follow/000008274?domain=https%3A%2F%2Fruby.social&label=%40hopsoft&style=social">
    </a>
    <a href="https://twitter.com/hopsoft">
      <img alt="Twitter Follow" src="https://img.shields.io/twitter/url?label=%40hopsoft&style=social&url=https%3A%2F%2Ftwitter.com%2Fhopsoft">
    </a>
  </p>
  <h2 align="center">Boost application speed and maximize user satisfaction with layered caching</h2>
</p>

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Why a composite cache?](#why-a-composite-cache)
    - [Gotchas](#gotchas)
  - [Sponsors](#sponsors)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Setup](#setup)
    - [Ruby on Rails](#ruby-on-rails)
  - [Usage](#usage)
  - [License](#license)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## Why a composite cache?

- __Improved performance__
- __Higher throughput__
- __Reduced load__
- __Enhanced capacity/scalability__

Layered caching enables a caching strategy that stacks multiple caches on top of each other
Each layer having a different scope, lifetime, and level of reliability.

The inner most layer is closest to the app's executing code, _typically in-memory in the same process_.
It provides the fastest reads but has the shortest lifetime for entries.

Outer layers are further away from the app's executing code,
_typically on another server running as a third-party service (Redis, Memcached, etc.)_.
Outer layers are also more likely to be shared by processes, dynos, and servers.

You can configure the cache to meet your specific requirements
with different expiration times, eviction policies, and storage mechanisms for each layer...
This puts you in control of balancing the trade-offs between performance and data freshness.

Think of it this way, "Inner layers are supersonic while outer layers are fast."
A cache hit on a local in-memory store compared to a cache hit on a remote out-of-memory store
is the equivalent of making a quick grocery run in a
[Bugatti Chiron Super Sport 300+](https://www.bugatti.com/models/chiron-models/chiron-super-sport-300/)
versus making the same trip on a bicyle.

It's worth noting layered caching techniques bear some of the hallmarks of distributed systems,
in that some layers may hold stale data until their entries expire.
Just be sure to __configure inner layers with shorter lifetimes__.
Note that this characteristic is also similar to the
[`race_condition_ttl`](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch-label-Options)
option in `ActiveSupport::Cache::Store`, which helps you avoid race conditions when multiple processes or threads attempt to write to the same cache key simultaneously.

### Gotchas

- __Data consistency__: it's possible to end up with inconsistent or stale data
- __Over-caching__: caching too much can lead to increased memory usage and even slower performance
- __Bugs/Testing__: difficult bugs can be introduced with sophisticated caching techniques

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
