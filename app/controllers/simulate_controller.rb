class SimulateController < ApplicationController
  def purchase
  end

  def pay
    purchase = params[:purchase]

    purchase_amount = BigDecimal.new(purchase[:amount])
    gateway_fees = purchase_amount * gateway_fee_rate
    atpay_fees = purchase_amount * atpay_fee_rate
    merchant_amount = purchase_amount - gateway_fees - atpay_fees

    money_service.payment_successfully_processed(
      transaction_id: purchase[:transaction_id],
      merchant_id: purchase[:merchant_id],
      purchase_amount: purchase_amount,
      merchant_amount: merchant_amount,
      gateway_fees: gateway_fees,
      atpay_fees: atpay_fees,
      reference_url: purchase[:reference_url],
      description: purchase[:description]
    )
  end

  def merchant_payout
  end

  def payout
    payout = params[:payout]
    payout_amount = BigDecimal.new(payout[:amount])

    money_service.payout_to_merchant(
      transaction_id: payout[:transaction_id],
      merchant_id: payout[:merchant_id],
      payout_amount: payout_amount,
      reference_url: payout[:reference_url],
      description: payout[:description]
    )
  end

private
  def gateway_fee_rate
    0.2
  end

  def atpay_fee_rate
    0.1
  end
end
