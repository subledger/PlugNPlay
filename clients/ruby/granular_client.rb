require_relative 'plug_n_play/client'

class GranularClient
  include PlugNPlay::Client

  def charge_buyer(transaction_id, purchase_amount, payment_fee, referrer_id, referrer_amount, publisher_id, publisher_amount, distributor_id, distributor_amount, reference_url, description)
    trigger("charge_buyer", {
      'transaction_id'     => transaction_id,
      'purchase_amount'    => purchase_amount,
      'payment_fee'        => payment_fee,
      'referrer_id'        => referrer_id,
      'referrer_amount'    => referrer_amount,
      'publisher_id'       => publisher_id,
      'publisher_amount'   => publisher_amount,
      'distributor_id'     => distributor_id,
      'distributor_amount' => distributor_amount,
      'reference_url'      => reference_url,
      'description'        => description
    })
  end

  def payout_referrer(transaction_id, referrer_id, payout_amount, reference_url, description)
    trigger("payout_referrer", {
      'transaction_id'  => transaction_id,
      'referrer_id'     => referrer_id,
      'payout_amount'   => payout_amount,
      'reference_url'   => reference_url,
      'description'     => description
    })
  end

  def payout_publisher(transaction_id, publisher_id, payout_amount, reference_url, description)
    trigger("payout_publisher", {
      'transaction_id'  => transaction_id,
      'publisher_id'    => publisher_id,
      'payout_amount'   => payout_amount,
      'reference_url'   => reference_url,
      'description'     => description
    })
  end

  def payout_distributor(transaction_id, distributor_id, payout_amount, reference_url, description)
    trigger("payout_distributor", {
      'transaction_id'  => transaction_id,
      'distributor_id'  => distributor_id,
      'payout_amount'   => payout_amount,
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
