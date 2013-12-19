class TriggerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(name, data)
    money_service.send name, data
  end

protected
  def money_service
    @money_service ||= MoneyService.new
  end  
end
