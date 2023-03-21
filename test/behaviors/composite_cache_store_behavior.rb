# frozen_string_literal: true

module CompositeCacheStoreBehavior
  extend ActiveSupport::Concern
  include CacheStoreBehavior

  tests_to_rewrite = %i[
    test_fetch_with_forced_cache_miss
    test_large_string_with_compress_true
    test_incompressible_data
    test_nil_with_compress_true
    test_fetch_with_cache_miss
    test_small_string_with_compress_true
    test_nil_with_compress_false
    test_race_condition_protection_skipped_if_not_defined
    test_large_string_with_high_compress_threshold
    test_cache_hit_instrumentation
    test_cache_miss_instrumentation
    test_fetch_with_dynamic_options
    test_format_of_expanded_key_for_single_instance
    test_format_of_expanded_key_for_single_instance_in_array
    test_large_object_with_compress_false
    test_large_object_with_compress_true
    test_large_object_with_high_compress_threshold
    test_large_string_with_compress_false
    test_nil_with_compress_low_compress_threshold
    test_nil_with_default_compression_settings
    test_small_object_with_compress_false
    test_small_object_with_compress_true
    test_small_object_with_default_compression_settings
    test_small_object_with_low_compress_threshold
    test_small_string_with_compress_false
    test_small_string_with_default_compression_settings
    test_small_string_with_low_compress_threshold
  ]

  tests_to_rewrite.each do |test|
    define_method test do
      skip "TODO: Rewrite or explain why test is not-applicable for stores that don't subclass ActiveSupport::Cache::Store"
    end
  end
end
