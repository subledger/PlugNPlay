class Api::ApplicationController < RocketPants::Base
  # check if app is correctly configured
  before_filter :check_app_ready

protected
  def money_service
    @money_service ||= MoneyService.new
  end

private
  def check_app_ready
    unless money_service.cached_setup_ready?
      error! :unknown, metadata: { error_message: "API app is not correctly configured yet" }
    end
  end
end
