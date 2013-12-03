require 'test_helper'

class SubledgerServiceTest < ActiveSupport::TestCase
  test "should create subledger service" do
    subledger_service = SubledgerService.new

    assert_not_nil subledger_service
    assert_not_nil subledger_service.subledger, "Did you set subledger env variables?"
  end
end
