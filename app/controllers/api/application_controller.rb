class Api::ApplicationController < RocketPants::Base
  # check for authentication
  before_filter :authenticate

  # check if app is correctly configured
  before_filter :check_app_ready

protected
  def setup_service
    @setup_service ||= SetupService.new
  end

  def subledger_service
    @subledger_service ||= SubledgerService.new
  end

private
  def check_app_ready
    unless setup_service.setup_ready?
      error! :unknown, metadata: { error_message: "API app is not correctly configured yet" }
    end
  end

  def authenticate
    if Rails.env.production?
      success = authenticate_with_http_basic do |user, password|
        config = Rails.application.config
        config.pnp_user == user and config.pnp_password == password
      end

      unless success
        request_http_basic_authentication
      end
    end
  end
end
