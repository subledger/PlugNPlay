class MoneyService

  def initialize()
  end

  def cached_get_setup
    Rails.cache.fetch(["app", "setup"]) { get_setup  }
  end

  def get_setup
    return {
      "subledger" => subledger_service.get_setup
    }
  end

  def cached_setup_ready?
    Rails.cache.fetch(["app", "ready"]) { setup_ready? }
  end

  def setup_ready?
    subledger_service.setup_ready?
  end

  def evict_cache
    Rails.cache.delete(["app", "setup"])
    Rails.cache.delete(["app", "ready"])
    @subledger_service = nil
  end

  def initial_setup(config)
    # subledger initial setup
    subledger_service.initial_setup(config[:subledger]) do |result|
      AppConfig.transaction do
        result.each do |key, value|
          AppConfig.create!(key: key, value: value)
        end
      end
    end

    # evict cache
    evict_cache

    return {
      "subledger" => subledger_service.cached_get_setup
    }
  end

  # This service method handles hooks for the invoicing a customer event. 
  # Event data should hold the following:
  #
  # customer_id: the id that identifies the customer entity on Sport Ngin app
  #
  # invoice_value: the full invoice value
  #
  # sportngin_value: the calculated value sportngin will receive from selling
  #                  this ticket
  #
  # organizations_values: the calculated values each organization will receive
  #                       from selling this ticket. Example:
  #   [
  #     { account_id: 'usaw_id'      , value: 45 , description: '...' },
  #     { account_id: 'minnesota_id' , value: 45 , description: '...' },
  #   ]
  #
  # reference_url: a url that identifies this transaction (the ticket show page
  #                for example)
  #
  # description: text that describes the transaction
  #
  # Example:
  #   invoice_customer(
  #     customer_id: "customer_email@example.com",
  #     invoice_value: 100,
  #     sportngin_value: 10,
  #     organizations_value: [
  #       { account_id: "usaw"     , value: 45 },
  #       { account_id: "minnesota", value: 45 }
  #     ],
  #     reference_url: "http://www.sportngin.com/ticket/123456",
  #     description: "Brazil vs Argentina Soccer Game"
  #   )
  #
  def invoice_customer(data)
    # call subledger service, so selling a ticket is automatically accounted for
    subledger_service.invoice_customer(
      data[:transaction_id],
      data[:customer_id],
      data[:invoice_value],
      data[:sportngin_value],
      data[:organizations_values],
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for when a customer pays an invoice event.
  # Event data should hold the following:
  #
  # customer_id: the id that identifies the customer entity on Sport Ngin app
  #
  # invoice_value: the full invoice value
  #
  # reference_url: a url that identifies this transaction (the ticket show page
  #                for example)
  #
  # description: text that describes the transaction
  #
  # Example:
  #   customer_invoice_payed(
  #     customer_id: "customer_email@example.com",
  #     invoice_value: 100,
  #     reference_url: "http://www.sportngin.com/ticket/123456",
  #     description: "Brazil vs Argentina Soccer Game"
  #   )
  #
  def customer_invoice_payed(data)
    # call subledger service, so an invoice payment is automatically account for
    subledger_service.customer_invoice_payed(
      data[:transaction_id],
      data[:customer_id],
      data[:invoice_value],
      data[:reference_url],
      data[:description]
    )
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
