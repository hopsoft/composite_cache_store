# frozen_string_literal: true

module CompositeCacheStoreCoderBehavior
  extend ActiveSupport::Concern
  include CacheStoreCoderBehavior

  def test_coder_receive_the_entry_on_write
    coder = SpyCoder.new
    @store = lookup_store(coder: coder)
    @store.write("foo", "bar")
    assert_equal @store.layers.size, coder.dumped_entries.size
    entry = coder.dumped_entries.first
    assert_instance_of ActiveSupport::Cache::Entry, entry
    assert_equal "bar", entry.value
  end

  def test_coder_receive_the_entry_on_write_multi
    coder = SpyCoder.new
    @store = lookup_store(coder: coder)
    @store.write_multi({"foo" => "bar", "egg" => "spam"})
    assert_equal @store.layers.size * 2, coder.dumped_entries.size
    entry = coder.dumped_entries.first
    assert_instance_of ActiveSupport::Cache::Entry, entry
    assert_equal "bar", entry.value

    entry = coder.dumped_entries[1]
    assert_instance_of ActiveSupport::Cache::Entry, entry
    assert_equal "spam", entry.value
  end
end
