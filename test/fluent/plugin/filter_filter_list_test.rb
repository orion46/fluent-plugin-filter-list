require 'test_helper'

class Fluent::FilterFilterListTest < Minitest::Test
  CONFIG = %[
  ]

  CONFIG_1 = %[
    key_to_filter x
    patterns_file_path test/fluent/plugin/patterns.txt
    <retag>
      tag t2
    </retag>
    <retag_filtered>
      add_prefix x
    </retag_filtered>
  ]

  CONFIG_2 = %[
    key_to_filter x
    patterns_file_path test/fluent/plugin/patterns.txt
    <retag>
      tag t2
    </retag>
  ]

  CONFIG_3 = %[
    key_to_filter abc
    patterns_file_path test/fluent/plugin/patterns.txt
    <retag>
      tag t
      add_prefix x
    </retag>
  ]

  CONFIG_4 = %[
    key_to_filter abc
    patterns_file_path test/fluent/plugin/patterns.txt
    <retag_filtered>
      tag t
      add_prefix x
    </retag_filtered>
  ]

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG, tag = 'test')
    Fluent::Test::FilterTestDriver.new(Fluent::FilterListFilter, tag).configure(conf, true)
  end

#   def test_that_tag_and_add_prefix_cannot_be_set_simultaneously_for_retag_section
#     assert_raises Fluent::ConfigError do
#       create_driver(CONFIG_3)
#     end
#   end
# 
#   def test_that_tag_and_add_prefix_cannot_be_set_simultaneously_for_retag_filtered_section
#     assert_raises Fluent::ConfigError do
#       create_driver(CONFIG_4)
#     end
#   end
# 
#   def test_config_without_retag_filtered
#     d = create_driver(CONFIG_2)
#     assert_equal "x", d.instance.key_to_filter
#     assert_equal "t2", d.instance.retag.tag
#     assert_nil d.instance.retag_for_filtered
#   end
# 
#   def test_matching_record_should_be_retagged_when_configured_to_do_so
#     d = create_driver(CONFIG_1, "t1")
#     d.run {
#       d.emit({ "a" => 1, "b" => 2, "x" => "ab"})
#       d.emit({ "a" => 1, "b" => 2, "x" => "abc"})
#       d.emit({ "a" => 1, "b" => 2, "x" => "xabcdef"})
#     }
#     emits = d.emits
#     assert_equal 3, emits.length
#     assert_equal ["t2", "x.t1", "x.t1"], emits.map { |e| e[0] } # tag
#   end
# 
#   def test_message_including_pattern_should_be_filtered_when_no_retag_filtered_section
#     d = create_driver(CONFIG_2, "t1")
#     d.run {
#       d.emit({ "a" => 1, "b" => 2, "x" => "ab"})
#       d.emit({ "a" => 1, "b" => 2, "x" => "xabcdef"})
#     }
#     emits = d.emits
#     assert_equal 1, emits.length
#     assert_equal "t2", emits[0][0] # tag
#   end
end