class Api::V1::EventController < Api::ApplicationController
  version 1

  def trigger
    # enforce parameters with strong_parameters
    trigger_params

    begin
      name = params[:name]
      data = params[:data]

      # check if method exists
      unless money_service.respond_to? name
        error! :not_found
      end

      # call the method
      money_service.send name, data
      
      # return ok message
      expose :ok

    rescue Exception => e
      error! :bad_request, metadata: { error_message: e.message }
    end
  end

private
  def trigger_params
    params.require(:name)
    params.require(:data).permit!
  end

  def money_service
    @money_service ||= MoneyService.new
  end
end
