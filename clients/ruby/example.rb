require_relative 'plug_n_play/client'

host="http://localhost:3000"
user="pnp"
pass="password"

if ARGV.length < 1
  puts "Need transaction id"
  puts "ex: ruby example.rb 100"
  exit
end

def goods_sold(client, transaction_id)
  puts "* Goods Sold"
  puts client.goods_sold(
    transaction_id: transaction_id,
    buyer_id: "buyer1@test.com",
    purchase_amount: "150",
    revenue_amount: "10",
    payables: [
      { id: "stripe",                amount: "9.25",   role: "payment_gateway" },
      { id: "referrer1@test.com",    amount: "20.10",  role: "referrer"        },
      { id: "publisher1@test.com",   amount: "40.90",  role: "publisher"       },
      { id: "distributor1@test.com", amount: "55",     role: "distributor"     },
      { id: "taxes1@test.com",       amount: "7.75",   role: "government"      },
      { id: "whatever1@test.com",    amount: "7  " ,   role: "whatever"        },
    ],
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Goods Sold #{transaction_id}"
  )
end

def card_charge_success(client, transaction_id)
  puts "* Card Charge Success"
  puts client.card_charge_success(
    transaction_id: transaction_id,
    buyer_id: "buyer1@test.com",
    purchase_amount: "150",
    intermediate_id: "stripe",
    intermediate_role: "payment_gateway",
    intermediation_fee: "9.25",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Card Charge Success #{transaction_id}"
  )
end

def payout_referrer(client, transaction_id)
  puts "Payout Referrer"
  puts client.payout_referrer(
    transaction_id: transaction_id,
    account_id: "referrer1@test.com",
    payout_amount: "20.10",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Payout Referrer #{transaction_id}"
  )
end

def payout_publisher(client, transaction_id)
  puts "* Payout Publisher"
  puts client.payout_publisher(
    transaction_id: transaction_id,
    account_id: "publisher1@test.com",
    payout_amount: "40.90",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Payout Publisher #{transaction_id}"
  )
end

def payout_distributor(client, transaction_id)
  puts "* Payout Distributor"
  puts client.payout_distributor(
    transaction_id: transaction_id,
    account_id: "distributor1@test.com",
    payout_amount: "55",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Payout Distributor #{transaction_id}"
  )
end

def payout_government(client, transaction_id)
  puts "* Payout Government"
  puts client.payout_government(
    transaction_id: transaction_id,
    account_id: "taxes1@test.com",
    payout_amount: "7.75",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Payout Government #{transaction_id}"
  )
end

def payout_whatever(client, transaction_id)
  puts "* Payout Whatever"
  puts client.payout_whatever(
    transaction_id: transaction_id,
    account_id: "whatever1@test.com",
    payout_amount: "7",
    reference_url: "http://testingapi.com/#{transaction_id}",
    description: "API Ruby Client Payout Whatever #{transaction_id}"
  )

  # the about call is the same as:
  # puts client.payout(
  #   transaction_id: transaction_id,
  #   account_id: "whatever1@test.com",
  #   account_role: "whatever",,
  #   payout_amount: "7",
  #   reference_url: "http://testingapi.com/#{transaction_id}",
  #   description: "API Ruby Client Payout Whatever #{transaction_id}"
  #)
end

# instantiate client
client = PlugNPlay::Client.new(host, user, pass)

# get transaction if from command line
transaction_id = ARGV[0]

goods_sold(client, transaction_id)
card_charge_success(client, transaction_id)
payout_referrer(client, transaction_id)
payout_publisher(client, transaction_id)
payout_distributor(client, transaction_id)
payout_government(client, transaction_id)
payout_whatever(client, transaction_id)
