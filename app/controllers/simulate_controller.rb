class SimulateController < ApplicationController
  def simulate_goods_sold
  end

  def goods_sold
    sold = params[:sold]

    purchase_amount    = BigDecimal.new(sold[:purchase_amount])
    referrer_amount    = BigDecimal.new(sold[:referrer_amount])
    publisher_amount   = BigDecimal.new(sold[:publisher_amount])
    distributor_amount = BigDecimal.new(sold[:distributor_amount])

    money_service.goods_sold(
      transaction_id: sold[:transaction_id],
      buyer_id: sold[:buyer_id],
      purchase_amount: purchase_amount,
      referrer_id: sold[:referrer_id],
      referrer_amount: referrer_amount,
      publisher_id: sold[:publisher_id],
      publisher_amount: publisher_amount,
      distributor_id: sold[:distributor_id],
      distributor_amount: distributor_amount,
      reference_url: sold[:reference_url],
      description: sold[:description]
    )
  end

  def simulate_card_charge_success
  end

  def card_charge_success
    charge = params[:charge]

    purchase_amount    = BigDecimal.new(charge[:purchase_amount])
    payment_fee        = BigDecimal.new(charge[:payment_fee])

    money_service.card_charge_success(
      transaction_id: charge[:transaction_id],
      buyer_id: charge[:buyer_id],
      purchase_amount: purchase_amount,
      payment_fee: payment_fee,
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
