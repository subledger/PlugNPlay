class SimulateController < ApplicationController
  def simulate_charge_buyer
  end

  def charge_buyer
    charge = params[:charge]

    purchase_amount    = BigDecimal.new(charge[:purchase_amount])
    payment_fee        = BigDecimal.new(charge[:payment_fee])
    referrer_amount    = BigDecimal.new(charge[:referrer_amount])
    publisher_amount   = BigDecimal.new(charge[:publisher_amount])
    distributor_amount = BigDecimal.new(charge[:distributor_amount])

    money_service.charge_buyer(
      transaction_id: charge[:transaction_id],
      purchase_amount: purchase_amount,
      payment_fee: payment_fee,
      referrer_id: charge[:referrer_id],
      referrer_amount: referrer_amount,
      publisher_id: charge[:publisher_id],
      publisher_amount: publisher_amount,
      distributor_id: charge[:distributor_id],
      distributor_amount: distributor_amount,
      reference_url: charge[:reference_url],
      description: charge[:description]
    )
  end

  def simulate_payout_referrer
  end

  def payout_referrer
    payout = params[:payout]
    payout_amount = BigDecimal.new(payout[:payout_amount])

    money_service.payout_referrer(
      transaction_id: payout[:transaction_id],
      referrer_id: payout[:referrer_id],
      payout_amount: payout_amount,
      reference_url: payout[:reference_url],
      description: payout[:description]
    )
  end

  def simulate_payout_publisher
  end

  def payout_publisher
    payout = params[:payout]
    payout_amount = BigDecimal.new(payout[:payout_amount])

    money_service.payout_publisher(
      transaction_id: payout[:transaction_id],
      publisher_id: payout[:publisher_id],
      payout_amount: payout_amount,
      reference_url: payout[:reference_url],
      description: payout[:description]
    )
  end

  def simulate_payout_distributor
  end

  def payout_distributor
    payout = params[:payout]
    payout_amount = BigDecimal.new(payout[:payout_amount])

    money_service.payout_distributor(
      transaction_id: payout[:transaction_id],
      distributor_id: payout[:distributor_id],
      payout_amount: payout_amount,
      reference_url: payout[:reference_url],
      description: payout[:description]
    )
  end
end
