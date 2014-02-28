class TriggerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  include Pnp::Dsl
  knows_accounting

  def perform(name, data)
    # symbolize data keys
    data = data.symbolize_keys

    # extract the transaction specific data
    transaction_data = data.extract! :transaction_id, :referece_url, :description

    # call the event
    lines = subledger_service.send name, data

    # post the transaction
    post_transaction name, transaction_data[:transaction_id], lines, {
      description: transaction_data[:description],
      reference_url: transaction_data[:reference_url]
    }
  end

protected
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end  
end
