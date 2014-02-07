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

  # This service method handles hooks for a goods sold event.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from your app, which we will map to subledger
  #                 transaction id
  #
  # buyer_id: the id that identifies the buyer entity on your app, which we
  #           will map to a subledger account_id
  #
  # purchase_amount: the full purchase value
  #
  # revenue_amount: the revenue generated on this event
  #
  # payables: an array of maps, with accounts that will need to be payed
  #
  # reference_url: a url that identifies this transaction (the transaction 
  #                show page, for example).
  #
  # description: text that describes the transaction
  #
  # Example:
  #   goods_sold(
  #     transaction_id: "100", // optional
  #     buyer_id: "buyer1_email@example.com", // doesnt need to be an email
  #     purchase_amount: "100",
  #     revenue: "25",
  #     payables: [
  #       {
  #         id: "referrer1_email@example.com", // doesnt need to be an email
  #         amount: "70",
  #         role: "referrer"
  #       },
  #       {
  #         id: "publisher1_email@example.com", // doesnt need to be an email
  #         amount: "10",
  #         role: "publisher"
  #       },
  #       {
  #         id: "distributor1_email@example.com", // doesnt need to be an email
  #         amount: "10",
  #         role: "distributor"
  #       }  #
  #     ]
  #     reference_url: "http://yourapp.com/transaction/100",
  #     description: "Purchase (customer@email.com)"
  #   )
  #
  def goods_sold(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so a successfull payment is automatically
    # accounted for
    subledger_service.goods_sold(
      data[:transaction_id],
      data[:buyer_id],
      BigDecimal.new(data[:purchase_amount]),
      BigDecimal.new(data[:revenue_amount]),
      data[:payables],
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for charging a buyer event.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from your app, which we will map to subledger
  #                 transaction id
  #
  # buyer_id: the id that identifies the buyer entity on your app, which we
  #           will map to a subledger account_id
  #
  # purchase_amount: the full purchase value
  #
  # payment_fee: the payment gateway fee
  #
  # reference_url: a url that identifies this transaction (the transaction 
  #                show page, for example).
  #
  # description: text that describes the transaction
  #
  # Example:
  #   charge_buyer(
  #     transaction_id: "100", // optional
  #     buyer_id: "buyer1_email@example.com", // doesnt need to be an email
  #     purchase_amount: "100",
  #     payment_fee: "10",
  #     reference_url: "http://yourapp.com/transaction/100",
  #     description: "Purchase (customer@email.com)"
  #   )
  #
  def card_charge_success(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so a successfull payment is automatically
    # accounted for
    subledger_service.card_charge_success(
      data[:transaction_id],
      data[:buyer_id],
      BigDecimal.new(data[:purchase_amount]),
      BigDecimal.new(data[:payment_fee]),
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for when a payout is made.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from your app, which we will map to subledger
  #                 transaction id
  #
  # account_id: the id that identifies the account entity on your app, which we
  #              will map to a subledger account_id
  #
  # account_role: the role of this account (for example, 'referrer', 'distributor', etc)
  #
  # payout_amount: the full payout value
  #
  # reference_url: a url on your app that identifies this transaction
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payout_referrer(
  #     transaction_id: "16", // optional
  #     account_id: "referrer1_email@example.com", // doesnt need to be an email
  #     account_role: "referrer",
  #     payout_amount: "160",
  #     reference_url: "http://yourapp.com/referrer/1/payout/16",
  #     description: "January 2014 Payout"
  #   )
  #
  def payout(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so an merchant payout is automatically account for
    subledger_service.payout(
      data[:transaction_id],
      data[:account_id],
      data[:account_role],
      BigDecimal.new(data[:payout_amount]),
      data[:reference_url],
      data[:description]
    )
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
