class Api::ApplicationController < RocketPants::Base
  # check for authentication
  before_filter :authenticate

  # check if app is correctly configured
  before_filter :check_app_ready

  def serializer(data, version)
    if data.class == Array
      { each_serializer: array_serializer(data, version) }
    else
      { serializer: object_serializer(data, version) }
    end
  end

  def array_serializer(data, version)
    if data.length > 0
      object_serializer data[0], version
    end
  end

  def object_serializer(data, version)
    case data
      when Subledger::Domain::Balance then balance_serializer(version)
      when Subledger::Domain::Line    then line_serializer(version)
      else puts "Nao era"
    end
  end

  def balance_serializer(version)
    case version.to_i
      when 1 then Api::V1::BalanceSerializer
      else Api::V1::BalanceSerializer
    end
  end

  def line_serializer(version)
    case version.to_i
      when 1 then Api::V1::LineSerializer
      else Api::V1::LineSerializer
    end
  end

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
