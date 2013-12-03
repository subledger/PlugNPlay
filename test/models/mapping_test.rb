require 'test_helper'

class MappingTest < ActiveSupport::TestCase
  test "should allow managing entity mappings" do
    key = "testing"
    Mapping.map_entity("account", key, "123")

    assert Mapping.entity_map_exists?("account", key)
    assert_not_nil Mapping.find_entity_map("account", key)
    assert_equal "123", Mapping.entity_map_value("account", key)
  end

  test "should not allow duplicated keys" do
    key = "testing"
    Mapping.map_entity("account", key, "123")

    assert_raise ActiveRecord::RecordInvalid do
      Mapping.map_entity("account", key, "123")
    end
  end

  test "should allow equal values on different keys" do
    value = "123"
    Mapping.map_entity("account", "testing1", "123")

    assert_nothing_raised do
      Mapping.map_entity("account", "testing2", "321")
    end
  end
end
