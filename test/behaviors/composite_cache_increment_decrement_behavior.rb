# frozen_string_literal: true

module CompositeCacheIncrementDecrementBehavior
  extend ActiveSupport::Concern
  include CacheIncrementDecrementBehavior

  def test_decrement
    key = SecureRandom.uuid
    @cache.write(key, 3, raw: true)
    assert_equal 3, @cache.read(key, raw: true).to_i
    assert_equal 2, @cache.decrement(key)
    assert_equal 2, @cache.read(key, raw: true).to_i
    assert_equal 1, @cache.decrement(key)
    assert_equal 1, @cache.read(key, raw: true).to_i

    missing = @cache.decrement(SecureRandom.alphanumeric)
    assert_equal(-1, missing)
    missing = @cache.decrement(SecureRandom.alphanumeric, 100)
    assert_equal(-100, missing)
  end
end
