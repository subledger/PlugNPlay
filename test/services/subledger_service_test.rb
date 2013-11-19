require 'test_helper'

class SubledgerServiceTest < ActiveSupport::TestCase
  test "should create subledger service" do
    subledger_service = SubledgerService.new

    assert_not_nil subledger_service
    assert_not_nil subledger_service.subledger, "Did you set subledger env variables?"
  end

  test "should create account mapping file if necessary" do
    if File.exists? ENV['SUBLEDGER_ACCOUNTS_MAPPING_FILE']
      File.delete ENV['SUBLEDGER_ACCOUNTS_MAPPING_FILE']
    end

    subledger_service = SubledgerService.new
    assert File.exists? ENV['SUBLEDGER_ACCOUNTS_MAPPING_FILE']
  end

  test "should allow adding account mappings" do
    subledger_service = SubledgerService.new

    key = "testing"
    subledger_service.add_accounts_mapping(key, "123")

    assert subledger_service.accounts_map.has_key? key
    assert_equal "123", subledger_service.accounts_map[key]

    subledger_service.load_accounts_map
    assert subledger_service.accounts_map.has_key? key
    assert_equal "123", subledger_service.accounts_map[key]
  end

end
