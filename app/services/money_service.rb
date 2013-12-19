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

  # This service method handles hooks for a successfully processed payment
  # event. Event data should hold the following:
  #
  # transaction_id: an optional id from atpay, which we will map to subledger
  #                 transaction id
  #
  # merchant_id: the id that identifies the merchant entity on atpay, which we
  #              will map to a subledger account_id
  #
  # purchase_amount: the full purchase value
  #
  # merchant_amount: value the merchant will receive
  #
  # gateway_fees: value the gateway charges
  #
  # atpay_fees: value atpay charges
  #
  # reference_url: a url on atpay that identifies this transaction (the transaction 
  #                show page, for example).
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payment_successfully_processed(
  #     transaction_id: "100", // optional
  #     merchant_id: "merchant1_email@example.com", // doesnt need to be an email
  #     purchase_amount: "100",
  #     merchant_amount: "80",
  #     gateway_amount: "10.10",
  #     atpay_amount: "9.90",
  #     reference_url: "http://www.atpay.com/transaction/100",
  #     description: "Brazil vs Argentina Soccer Game"
  #   )
  #
  def payment_successfully_processed(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so a successfull payment is automatically
    # accounted for
    subledger_service.payment_successfully_processed(
      data[:transaction_id],
      data[:merchant_id],
      data[:purchase_amount],
      data[:merchant_amount],
      data[:gateway_fees],
      data[:atpay_fees],
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for when a payout for a merchant is made.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from atpay, which we will map to subledger
  #                 transaction id
  #
  # merchant_id: the id that identifies the merchant entity on atpay, which we
  #              will map to a subledger account_id
  #
  # payout_amount: the full payout value
  #
  # reference_url: a url on atpay that identifies this transaction
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payout_to_merchant(
  #     transaction_id: "16", // optional
  #     merchant_id: "merchant1_email@example.com", // doesnt need to be an email
  #     payout_amount: "160",
  #     reference_url: "http://www.atpay.com/merchant/1/payout/16",
  #     description: "January 2014 Payout"
  #   )
  #
  def payout_to_merchant(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so an merchant payout is automatically account for
    subledger_service.payout_to_merchant(
      data[:transaction_id],
      data[:merchant_id],
      data[:payout_amount],
      data[:reference_url],
      data[:description]
    )
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
