class TriggerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(name, data)
    subledger_service.send name, data
  end

protected
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end  
end
