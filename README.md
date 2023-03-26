<p align="center">
  <h1 align="center">CompositeCacheStore 🚀</h1>
  <p align="center">
    <a href="http://blog.codinghorror.com/the-best-code-is-no-code-at-all/">
      <img alt="Lines of Code" src="https://img.shields.io/badge/loc-133-47d299.svg" />
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

  - [Sponsors](#sponsors)
  - [Why a composite cache?](#why-a-composite-cache)
  - [Eventual consistentency](#eventual-consistentency)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Setup](#setup)
  - [Usage](#usage)
  - [License](#license)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## Sponsors

<p align="center">
  <em>Proudly sponsored by</em>
</p>
<p align="center">
  <a href="https://www.clickfunnels.com?utm_source=hopsoft&utm_medium=open-source&utm_campaign=composite_cache_store">
    <img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" />
  </a>
</p>

## Why a composite cache?

Layered caching allows you to stack multiple caches with different scopes, lifetimes, and levels of reliability.
A technique that yields several benefits.

- __Improved performance__
- __Higher throughput__
- __Reduced load__
- __Enhanced capacity/scalability__

Inner cache layer(s) provide the fastest reads as they're close to the application, _typically in-memory within the same process_.
Outer layers are slower _(still fast)_ but are shared by multiple processes and servers.

<img height="250" src="https://ik.imagekit.io/hopsoft/composite_cache_store_jnHZcjAuK.svg?updatedAt=1679445477496" />

You can configure each layer with different expiration times, eviction policies, and storage mechanisms.
You're in control of balancing the trade-offs between performance and data freshness.

__Inner layers are supersonic while outer layers are speedy.__

The difference between a cache hit on a local in-memory store versus a cache hit on a remote store
is similar to making a grocery run in a
[Bugatti Chiron Super Sport 300+](https://www.bugatti.com/models/chiron-models/chiron-super-sport-300/)
compared to making the same trip on a bicyle, but all cache layers will be much faster than the underlying operations.
For example, a complete cache miss _(that triggers database queries and view rendering)_ would be equivalent to making this trip riding a sloth.

## Eventual consistentency

Layered caching techniques exhibit some of the same traits as [distributed systems](https://en.wikipedia.org/wiki/Eventual_consistency)
because inner layers may hold onto __stale data__ until their entries expire.
__Be sure to configure inner layers appropriately with shorter lifetimes__.

This behavior is similar to the
[`race_condition_ttl`](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch-label-Options)
option in `ActiveSupport::Cache::Store` which helps to avoid race conditions whenever multiple threads/processes try to write to the same cache entry simultaneously.

__Be mindful of the potential gotchas.__

- __Data consistency__ - it's possible to end up with inconsistent or stale data
- __Over-caching__ - caching too much can lead to increased memory usage and even slower performance
- __Bugs/Testing__ - difficult bugs can be introduced with sophisticated caching techniques

## Dependencies

- [ActiveSupport `>= 6.0`](https://github.com/rails/rails/tree/main/activesupport)

## Installation

```sh
bundle add "composite_cache_store"
```

## Setup

Here's an example of how you might set up layered caching in a Rails application.

```ruby
# config/initializers/composite_cache_store.rb
def Rails.composite_cache
  @composite_cache ||= CompositeCacheStore.new(
    layers: [
      # Layer 1 cache (fastest)
      # Most beneficial for high traffic volume
      # Isolated to the process running an application instance
      ActiveSupport::Cache::MemoryStore.new(
        expires_in: 15.minutes,
        size: 32.megabytes
      ),

      # Layer 2 cache (faster)
      # Most beneficial for moderate traffic volume
      # Isolated to the machine running N-number of application instances,
      # and shared by all application processes on the machine
      ActiveSupport::Cache::RedisCacheStore.new(
        url: "redis://localhost:6379/0",
        expires_in: 2.hours
      ),

      # Layer 3 cache (fast)
      # Global cache shared by all application processes on all machines
      ActiveSupport::Cache::RedisCacheStore.new(
        url: "redis://remote.example.com:6379/0",
        expires_in: 7.days
      ),

      # additional layers are optional
    ]
  )
end
```

## Usage

A composite cache is ideal for mitigating hot spot latency in frequently invoked areas of the codebase.

```ruby
# method that's invoked frequently by multiple processes/machines
def hotspot
  Rails.composite_cache.fetch("example", expires_in: 12.hours) do
    # computationally expensive operation with high latency...
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
