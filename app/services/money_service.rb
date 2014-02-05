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
  # transaction_id: an optional id from granular, which we will map to subledger
  #                 transaction id
  #
  # buyer_id: the id that identifies the buyer entity on granular, which we
  #           will map to a subledger account_id
  #
  # purchase_amount: the full purchase value
  #
  # referrer_id: the id that identifies the referrer entity on granular, which we
  #              will map to a subledger account_id
  #
  # referrer_fee: the fee the referrer charges
  #
  # publisher_id: the id that identifies the publisher entity on granular, which we
  #              will map to a subledger account_id
  #
  # publisher_fee: the fee the publisher charges
  #
  # distributor_id: the id that identifies the distributor entity on granular, which we
  #              will map to a subledger account_id
  #
  # distributor_fee: the fee the distributor charges
  #
  # reference_url: a url on granular that identifies this transaction (the transaction 
  #                show page, for example).
  #
  # description: text that describes the transaction
  #
  # Example:
  #   charge_buyer(
  #     transaction_id: "100", // optional
  #     buyer_id: "buyer1_email@example.com", // doesnt need to be an email
  #     purchase_amount: "100",
  #     referrer_id: "referrer1_email@example.com", // doesnt need to be an email
  #     referrer_amount: "70",
  #     publisher_id: "publisher1_email@example.com", // doesnt need to be an email
  #     publisher_amount: "10",
  #     distributor_id: "distributor1_email@example.com", // doesnt need to be an email
  #     distributor_amount: "10",
  #     reference_url: "http://getgranular.com/transaction/100",
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
      data[:referrer_id],
      BigDecimal.new(data[:referrer_amount]),
      data[:publisher_id],
      BigDecimal.new(data[:publisher_amount]),
      data[:distributor_id],
      BigDecimal.new(data[:distributor_amount]),
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for charging a buyer event.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from granular, which we will map to subledger
  #                 transaction id
  #
  # buyer_id: the id that identifies the buyer entity on granular, which we
  #           will map to a subledger account_id
  #
  # purchase_amount: the full purchase value
  #
  # payment_fee: the payment gateway fee
  #
  # reference_url: a url on granular that identifies this transaction (the transaction 
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
  #     reference_url: "http://getgranular.com/transaction/100",
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
  # This service method handles hooks for when a payout for a referrer is made.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from granular, which we will map to subledger
  #                 transaction id
  #
  # referrer_id: the id that identifies the referrer entity on granular, which we
  #              will map to a subledger account_id
  #
  # payout_amount: the full payout value
  #
  # reference_url: a url on granular that identifies this transaction
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payout_referrer(
  #     transaction_id: "16", // optional
  #     referrer_id: "referrer1_email@example.com", // doesnt need to be an email
  #     payout_amount: "160",
  #     reference_url: "http://getgranular.com/referrer/1/payout/16",
  #     description: "January 2014 Payout"
  #   )
  #
  def payout_referrer(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so an merchant payout is automatically account for
    subledger_service.payout_referrer(
      data[:transaction_id],
      data[:referrer_id],
      BigDecimal.new(data[:payout_amount]),
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for when a payout for a publisher is made.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from granular, which we will map to subledger
  #                 transaction id
  #
  # publisher_id: the id that identifies the publisher entity on granular, which we
  #              will map to a subledger account_id
  #
  # payout_amount: the full payout value
  #
  # reference_url: a url on granular that identifies this transaction
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payout_referrer(
  #     transaction_id: "16", // optional
  #     publisher_id: "publisher1_email@example.com", // doesnt need to be an email
  #     payout_amount: "160",
  #     reference_url: "http://getgranular.com/publisher/1/payout/16",
  #     description: "January 2014 Payout"
  #   )
  #
  def payout_publisher(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so an merchant payout is automatically account for
    subledger_service.payout_publisher(
      data[:transaction_id],
      data[:publisher_id],
      BigDecimal.new(data[:payout_amount]),
      data[:reference_url],
      data[:description]
    )
  end

  # This service method handles hooks for when a payout for a distributor is made.
  # Event data should hold the following:
  #
  # transaction_id: an optional id from granular, which we will map to subledger
  #                 transaction id
  #
  # distributor_id: the id that identifies the referrer entity on granular, which we
  #              will map to a subledger account_id
  #
  # payout_amount: the full payout value
  #
  # reference_url: a url on granular that identifies this transaction
  #
  # description: text that describes the transaction
  #
  # Example:
  #   payout_referrer(
  #     transaction_id: "16", // optional
  #     distributor_id: "distributor1_email@example.com", // doesnt need to be an email
  #     payout_amount: "160",
  #     reference_url: "http://getgranular.com/distributor/1/payout/16",
  #     description: "January 2014 Payout"
  #   )
  #
  def payout_distributor(data)
    # convert string keys to symbols
    data = data.symbolize_keys

    # call subledger service, so an merchant payout is automatically account for
    subledger_service.payout_distributor(
      data[:transaction_id],
      data[:distributor_id],
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
