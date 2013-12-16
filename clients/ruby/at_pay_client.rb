require_relative 'plug_n_play/client'

class AtPayClient
  include PlugNPlay::Client

  def payment_successfully_processed(transaction_id, merchant_id, purchase_amount, merchant_amount, gateway_fees, atpay_fees, reference_url, description)
    trigger("payment_successfully_processed", {
      'transaction_id'  => transaction_id,
      'merchant_id'     => merchant_id,
      'purchase_amount' => purchase_amount,
      'merchant_amount' => merchant_amount,
      'gateway_fees'    => gateway_fees,
      'atpay_fees'      => atpay_fees,
      'reference_url'   => reference_url,
      'description'     => description
    })
  end

  def payout_to_merchant(transaction_id, merchant_id, payout_amount, reference_url, description)
    trigger("payout_to_merchant", {
      'transaction_id'  => transaction_id,
      'merchant_id'     => merchant_id,
      'purchase_amount' => purchase_amount,
      'reference_url'   => reference_url,
      'description'     => description
    })
  end

  def initialize(uri, user, password, timeout = 60)
    @pnp_uri = uri
    @pnp_user = user
    @pnp_password = password
    @pnp_timeout = timeout
  end
end
