class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # check for authentication
  before_filter :authenticate

  # check if app is correctly configured
  before_filter :check_app_ready

protected
  def money_service
    @money_service ||= MoneyService.new
  end

private
  def check_app_ready
    if not (controller_name == "setups" and ["new", "create"].include?(action_name)) and
       not money_service.cached_setup_ready?

      redirect_to new_setup_path
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
