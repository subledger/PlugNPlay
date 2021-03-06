class Api::V1::EventController < Api::ApplicationController
  version 1

  def trigger
    # enforce parameters with strong_parameters
    trigger_params

    begin
      name = params[:name]
      data = params[:data]

      # check if method exists
      unless subledger_service.respond_to? name
        error! :not_found
      end

      # call the method
      TriggerWorker.perform_async name, data
      
      # return ok message
      expose :ok

    rescue Exception => e
      #logger.error e.backtrace
      error! :bad_request, metadata: { error_message: e.message }
    end
  end

private
  def trigger_params
    params.require(:name)
    params.require(:data).permit!
  end
end
