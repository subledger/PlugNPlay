require_relative 'plug_n_play/client'

client = PlugNPlay::Client.new("http://localhost:3000", "pnp", "password")
transaction_id = ARGV[0]

if ARGV.length < 1
  puts "Need transaction id"
  puts "ex: ruby example.rb 100"
  exit
end

puts "* Goods Sold"
puts client.goods_sold(
  transaction_id: transaction_id,
  buyer_id: "buyer1@test.com",
  purchase_amount: "100",
  referrer_id: "referrer1@test.com",
  referrer_amount: "25",
  publisher_id: "publisher1@test.com",
  publisher_amount: "25",
  distributor_id: "distributor1@test.com",
  distributor_amount: "25",
  reference_url: "http://testingapi.com/#{transaction_id}",
  description: "API Ruby Client Goods Sold #{transaction_id}"
)

puts "* Card Charge Success"
puts client.card_charge_success(
  transaction_id: transaction_id,
  buyer_id: "buyer1@test.com",
  purchase_amount: "100",
  payment_fee: "10",
  reference_url: "http://testingapi.com/#{transaction_id}",
  description: "API Ruby Client Card Charge Success #{transaction_id}"
)

puts "Payout Referrer"
puts client.payout_referrer(
  transaction_id: transaction_id,
  referrer_id: "referrer1@test.com",
  payout_amount: "25",
  reference_url: "http://testingapi.com/#{transaction_id}",
  description: "API Ruby Client Payout Referrer #{transaction_id}"
)

puts "* Payout Publisher"
puts client.payout_publisher(
  transaction_id: transaction_id,
  publisher_id: "publisher1@test.com",
  payout_amount: "25",
  reference_url: "http://testingapi.com/#{transaction_id}",
  description: "API Ruby Client Payout Publisher #{transaction_id}"
)

puts "* Payout Distributor"
puts client.payout_distributor(
  transaction_id: transaction_id,
  distributor_id: "distributor1@test.com",
  payout_amount: "25",
  reference_url: "http://testingapi.com/#{transaction_id}",
  description: "API Ruby Client Payout Distributor #{transaction_id}"
)
