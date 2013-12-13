require_relative 'plug_n_play/client'

class Pnp_Client
  include PlugNPlay::Client

  def invoice_customer(transaction_id, customer_id, invoice_value, sportngin_value, reference_url, description, organizations_values)
    trigger("invoice_customer", {
      'transaction_id'        => transaction_id,
      'customer_id'           => customer_id,
      'invoice_value'         => invoice_value,
      'sportngin_value'       => sportngin_value,
      'reference_url'         => reference_url,
      'description'           => description,
      'organizations_values'  => organizations_values
    })
  end

  def customer_invoice_payed(transaction_id, invoice_value, reference_url, description)
    trigger("customer_invoice_payed", {
      'transaction_id'        => transaction_id,
      'customer_id'           => customer_id,
      'invoice_value'         => invoice_value,
      'reference_url'         => reference_url,
      'description'           => description
    })
  end

  def initialize(uri, timeout)
    @pnp_uri = uri
    @pnp_timeout = timeout
  end
end
