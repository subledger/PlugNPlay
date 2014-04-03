class Api::V1::EventController < Api::ApplicationController
  version 1
  around_action :as_subledger_event

  def read
    # call the service method synchronously
    result = subledger_service.send(@name, @data)

    # get the json serializer
    expose_options = serializer result, params[:version]

    # return the json response
    expose result, expose_options
  end

  def trigger
    # enqueue event for deferred execution
    TriggerWorker.perform_async @name, @data

    # return ok message
    expose :ok
  end

private
  def as_subledger_event
    event_params

    @name = params[:name]
    @data = params[:data].symbolize_keys

    # check if method exists
    unless subledger_service.respond_to? @name
      error! :not_found
    end

    # call the method
    yield
  end

  def event_params
    params.require(:name)
    params.require(:data).permit!
  end
end
