require_relative 'plug_n_play/client'

class CustomClient
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

  def initialize(uri)
    @pnp_uri = uri 
  end
end

client = CustomClient.new('http://localhost:3000')
puts client.invoice_customer(104, 'alex', '123.33', '23.33', 'http://testingapi.com', 'Testing Client', [
  { 'account_id' => 'usaw',      'value' => '50' },
  { 'account_id' => 'minnesota', 'value' => '50' }
])
