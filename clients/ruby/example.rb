require 'time'
require 'bigdecimal'
require_relative 'plug_n_play/client'

host="http://localhost:3000"
user="pnp"
pass="password"

if ARGV.length < 1
  puts "ruby example.rb <example_name> [<transaction_id>]"
  puts "ex: ruby example.rb full 1"
  exit
end

### example Utils
def calc_intermediate_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.01')).to_s
end

def calc_referrer_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.1')).to_s
end

def calc_publisher_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.1')).to_s
end

def calc_distributor_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.1')).to_s
end

def calc_government_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.05')).to_s
end

def calc_whatever_amount(total)
  return (BigDecimal.new(total) * BigDecimal.new('0.01')).to_s
end


### PnP API Calls

def user_adds_credit_using_credit_card(client, transaction_id, user_id, payment_amount, intermediate_id)
  puts "* User Adds Credit Using Credit Card"

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(payment_amount)

  puts client.user_adds_credit_using_credit_card(
    transaction_id: transaction_id,
    user_id: user_id,
    payment_amount: payment_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    reference_url: "http://yourapp.com/user_adds_credit_using_credit_card/#{transaction_id}",
    description: "User Adds Credit Using Credit Card #{transaction_id}: #{user_id}"
  )
end

def user_credit_added_successfully(client, transaction_id, user_id, payment_amount, intermediate_id)
  puts "* User Credit Added Successfully"

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(payment_amount)

  puts client.user_credit_added_successfully(
    transaction_id: transaction_id,
    user_id: user_id,
    payment_amount: payment_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    reference_url: "http://yourapp.com/user_credit_added_successfully/#{transaction_id}",
    description: "User Credit Added Successfully #{transaction_id}: #{user_id}"
  )
end

def purchase_with_balanced(client, transaction_id, user_id, purchase_amount, referrer_id, publisher_id, distributor_id, government_id, whatever_id)
  puts "* Purchase With Balance"

  # calculate each payable amount
  referrer_amount     = calc_referrer_amount(purchase_amount)
  publisher_amount    = calc_publisher_amount(purchase_amount)
  distributor_amount  = calc_distributor_amount(purchase_amount)
  government_amount   = calc_government_amount(purchase_amount)
  whatever_amount     = calc_whatever_amount(purchase_amount)

  # calculate reveneue (remainder)
  revenue_amount  = BigDecimal.new(purchase_amount)
  revenue_amount -= BigDecimal.new(referrer_amount)
  revenue_amount -= BigDecimal.new(publisher_amount)
  revenue_amount -= BigDecimal.new(distributor_amount)
  revenue_amount -= BigDecimal.new(government_amount)
  revenue_amount -= BigDecimal.new(whatever_amount)
  revenue_amount  = revenue_amount.to_s

  # make the api call
  puts client.purchase_with_balance(
    transaction_id: transaction_id,
    user_id: user_id,
    purchase_amount: purchase_amount,
    revenue_amount: revenue_amount,
    payables: [
      { id: referrer_id   , amount: referrer_amount   ,  role: "referrer"    },
      { id: publisher_id  , amount: publisher_amount  ,  role: "publisher"   },
      { id: distributor_id, amount: distributor_amount,  role: "distributor" },
      { id: government_id , amount: government_amount ,  role: "government"  },
      { id: whatever_id   , amount: whatever_amount   ,  role: "whatever"    },
    ],
    reference_url: "http://yourapp.com/purchase_with_balance/#{transaction_id}",
    description: "Purchase With Balance #{transaction_id}: #{user_id}"
  )
end

def refund_purchase_to_user_account(client, transaction_id, user_id, refund_amount, referrer_id, publisher_id, distributor_id, government_id, whatever_id)
  puts "* Refund Purchase to User Account"

  # calculate each payable amount
  referrer_amount     = calc_referrer_amount(refund_amount)
  publisher_amount    = calc_publisher_amount(refund_amount)
  distributor_amount  = calc_distributor_amount(refund_amount)
  government_amount   = calc_government_amount(refund_amount)
  whatever_amount     = calc_whatever_amount(refund_amount)

  # calculate reveneue (remainder)
  revenue_amount  = BigDecimal.new(refund_amount)
  revenue_amount -= BigDecimal.new(referrer_amount)
  revenue_amount -= BigDecimal.new(publisher_amount)
  revenue_amount -= BigDecimal.new(distributor_amount)
  revenue_amount -= BigDecimal.new(government_amount)
  revenue_amount -= BigDecimal.new(whatever_amount)
  revenue_amount  = revenue_amount.to_s

  # make the api call
  puts client.refund_purchase_to_user_account(
    transaction_id: transaction_id,
    user_id: user_id,
    refund_amount: refund_amount,
    revenue_amount: revenue_amount,
    payables: [
      { id: referrer_id   , amount: referrer_amount   ,  role: "referrer"    },
      { id: publisher_id  , amount: publisher_amount  ,  role: "publisher"   },
      { id: distributor_id, amount: distributor_amount,  role: "distributor" },
      { id: government_id , amount: government_amount ,  role: "government"  },
      { id: whatever_id   , amount: whatever_amount   ,  role: "whatever"    },
    ],
    reference_url: "http://yourapp.com/refund_purchase_to_user_account/#{transaction_id}",
    description: "Refund Purchase to User Account #{transaction_id}: #{user_id}"
  )
end

def transfer_to_external_account(client, transaction_id, user_id, transfer_amount, intermediate_id)
  puts "* Transfer to External Account"

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(transfer_amount)

  # make the api call
  puts client.transfer_to_external_account(
    transaction_id: transaction_id,
    user_id: user_id,
    transfer_amount: transfer_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    reference_url: "http://yourapp.com/transfer_to_external_account/#{transaction_id}",
    description: "Transfer to External Account #{transaction_id}: #{user_id}"
  )
end

def transfer_to_external_account_successfull(client, transaction_id, user_id, transfer_amount, intermediate_id)
  puts "* Transfer to External Account Successfull"

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(transfer_amount)

  # make the api call
  puts client.transfer_to_external_account_successfull(
    transaction_id: transaction_id,
    user_id: user_id,
    transfer_amount: transfer_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    reference_url: "http://yourapp.com/transfer_to_external_account_successfull/#{transaction_id}",
    description: "Transfer to External Account Successfull#{transaction_id}: #{user_id}"
  )
end

def transfer_to_wallet(client, transaction_id, user_id, user_role, transfer_amount)
  puts "* Transfer to Wallet"

  # make the api call
  puts client.transfer_to_wallet(
    transaction_id: transaction_id,
    user_id: user_id,
    user_role: user_role,
    transfer_amount: transfer_amount,
    reference_url: "http://yourapp.com/transfer_to_wallet/#{transaction_id}",
    description: "Transfer to Wallet #{transaction_id}: #{user_id}"
  )
end

def purchase_with_credit_card(client, transaction_id, user_id, purchase_amount, intermediate_id, referrer_id, publisher_id, distributor_id, government_id, whatever_id)
  puts "* Purchase With Credit Card"

  # calculate each payable amount
  intermediate_amount = calc_intermediate_amount(purchase_amount)
  referrer_amount     = calc_referrer_amount(purchase_amount)
  publisher_amount    = calc_publisher_amount(purchase_amount)
  distributor_amount  = calc_distributor_amount(purchase_amount)
  government_amount   = calc_government_amount(purchase_amount)
  whatever_amount     = calc_whatever_amount(purchase_amount)

  # calculate reveneue (remainder)
  revenue_amount  = BigDecimal.new(purchase_amount)
  revenue_amount -= BigDecimal.new(intermediate_amount)
  revenue_amount -= BigDecimal.new(referrer_amount)
  revenue_amount -= BigDecimal.new(publisher_amount)
  revenue_amount -= BigDecimal.new(distributor_amount)
  revenue_amount -= BigDecimal.new(government_amount)
  revenue_amount -= BigDecimal.new(whatever_amount)
  revenue_amount  = revenue_amount.to_s

  # make the api call
  puts client.purchase_with_credit_card(
    transaction_id: transaction_id,
    user_id: user_id,
    purchase_amount: purchase_amount,
    revenue_amount: revenue_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    payables: [
      { id: referrer_id   , amount: referrer_amount   ,  role: "referrer"    },
      { id: publisher_id  , amount: publisher_amount  ,  role: "publisher"   },
      { id: distributor_id, amount: distributor_amount,  role: "distributor" },
      { id: government_id , amount: government_amount ,  role: "government"  },
      { id: whatever_id   , amount: whatever_amount   ,  role: "whatever"    },
    ],
    reference_url: "http://yourapp.com/purchase_with_credit_card/#{transaction_id}",
    description: "Purchase With Credit Card #{transaction_id}: #{user_id}"
  )
end

def credit_card_charge_success(client, transaction_id, user_id, purchase_amount, intermediate_id)
  puts "* Credit Card Charge Success"

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(purchase_amount)

  # make the api call
  puts client.credit_card_charge_success(
    transaction_id: transaction_id,
    user_id: user_id,
    purchase_amount: purchase_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    reference_url: "http://yourapp.com/credit_card_charge_success/#{transaction_id}",
    description: "Credit Card Charge Success #{transaction_id}: #{user_id}"
  )
end

def refund_to_credit_card(client, transaction_id, user_id, refund_amount, intermediate_id, referrer_id, publisher_id, distributor_id, government_id, whatever_id)
  puts "* Refund to Credit Card"

  # calculate each payable amount
  intermediate_amount = calc_intermediate_amount(refund_amount)
  referrer_amount     = calc_referrer_amount(refund_amount)
  publisher_amount    = calc_publisher_amount(refund_amount)
  distributor_amount  = calc_distributor_amount(refund_amount)
  government_amount   = calc_government_amount(refund_amount)
  whatever_amount     = calc_whatever_amount(refund_amount)

  # calculate reveneue (remainder)
  revenue_amount  = BigDecimal.new(refund_amount)
  revenue_amount -= BigDecimal.new(intermediate_amount)
  revenue_amount -= BigDecimal.new(referrer_amount)
  revenue_amount -= BigDecimal.new(publisher_amount)
  revenue_amount -= BigDecimal.new(distributor_amount)
  revenue_amount -= BigDecimal.new(government_amount)
  revenue_amount -= BigDecimal.new(whatever_amount)
  revenue_amount  = revenue_amount.to_s

  # make the api call
  puts client.refund_to_credit_card(
    transaction_id: transaction_id,
    user_id: user_id,
    refund_amount: refund_amount,
    revenue_amount: revenue_amount,
    intermediate_id: intermediate_id,
    intermediate_role: "payment_gateway",
    intermediation_fee: intermediate_amount,
    payables: [
      { id: referrer_id   , amount: referrer_amount   ,  role: "referrer"    },
      { id: publisher_id  , amount: publisher_amount  ,  role: "publisher"   },
      { id: distributor_id, amount: distributor_amount,  role: "distributor" },
      { id: government_id , amount: government_amount ,  role: "government"  },
      { id: whatever_id   , amount: whatever_amount   ,  role: "whatever"    },
    ],
    reference_url: "http://yourapp.com/refund_to_credit_card/#{transaction_id}",
    description: "Refund to Credit Card #{transaction_id}: #{user_id}"
  )
end

def payout(client, transaction_id, account_id, account_role, payout_amount)
  puts "* Payout #{account_role}: #{account_id}"

  # make the api call
  puts client.payout(
    transaction_id: transaction_id,
    account_id: account_id,
    account_role: account_role,
    payout_amount: payout_amount,
    reference_url: "http://yourapp.com/payout/#{transaction_id}",
    description: "Payout #{account_role}: #{account_id}"
  )
end

def get_account_balance(client, user_id, sufixes)
  puts "* Get Account Balance #{user_id}"

  # time must be in iso 8601 format
  at = Time.now.iso8601

  # make the api call
  result = client.get_user_balance(
    user_id: user_id,
    sufixes: sufixes,
    at: at
  )

  # print the balance
  balance = result[:response][:value]
  puts "#{balance[:type]}: #{balance[:amount]}"
end

def get_account_history(client, user_id, sufixes)
  puts "* Get Account History #{user_id}"

  # time must be in iso 8601 format
  at = Time.now.iso8601

  page_id = nil
  lines = nil

  begin
    result = client.get_user_history(
      user_id: user_id,
      sufixes: sufixes,
      date: at,
      order: "desc",
      page_id: page_id,
      per_page: 5
    )

    lines = result[:response]

    lines.each do |line|
      page_id = line[:id]
      balance = line[:balance][:value]

      puts "#{balance[:type]} #{balance[:amount]} => #{line[:description]}"
    end
  end while not lines.empty?
end


### Examples

# Example Full
# ------------
#
# 1) The user adds credit to his wallet using a credit card (through an
#    intermediation partner - ex: stripe)
#
# 2) The user then makes a purchase from his outstanding balance
#
# 3) The user then withdraw the ramaining balance from his wallet
#
# 4) The user, that now not enough balance on his wallet, makes a purchase from
#    his credit card
#
# 5) The referrer transfer the amount he made to his wallet
#
# 7) We payout the publisher, distributor, government and whatever
#
# Ex: ruby example.rb full <transaction_id>
#
def example_full(client, transaction_id)
  puts "** Running Example: Full"

  # 1) user adds credit using credit card (through an intermediation partner - stripe)
  user_adds_credit_using_credit_card(client, transaction_id, "user1", "200", "stripe")

  # 1) intermediation partner confirms payment
  user_credit_added_successfully(client, transaction_id, "user1", "200", "stripe")

  # 2) now user has balance on his wallet, so he places an other
  purchase_with_balanced(client, transaction_id, "user1", "50", "referrer1", "publisher1", "distributor1", "government1", "whatever1")

  # 3) user transfer money to his bank account
  transfer_to_external_account(client, transaction_id, "user1", "80", "stripe")

  # 3) intermediation partner confirms payment
  transfer_to_external_account_successfull(client, transaction_id, "user1", "80", "stripe")

  # 4) user makes a purchase from credit card
  purchase_with_credit_card(client, transaction_id, "user1", "300", "stripe", "referrer1", "publisher1", "distributor1", "government1", "whatever1")

  # 4) intermediation partner confirms payment
  credit_card_charge_success(client, transaction_id, "user1", "300", "stripe")

  # 5) referrer transfer part of the money he made to his wallet
  transfer_to_wallet(client, transaction_id, "referrer1", "referrer", "20")

  # 6) payouts
  payout(client, transaction_id, "publisher1", "publisher", "10")
  payout(client, (transaction_id.to_i + 100).to_s, "distributor1", "distributor", "10")
  payout(client, (transaction_id.to_i + 1000).to_s, "government1", "government", "10")
  payout(client, (transaction_id.to_i + 10000).to_s, "whatever1", "whatever", "1")
end

# Example Refund Account
# ----------------------
#
# 1) The user adds credit to his wallet using a credit card (through an
#    intermediation partner - ex: stripe)
#
# 2) The user then makes a purchase from his outstanding balance
#
# 3) User 'cancel' purchase, and the amount is refunded to his account/wallet
#
# Ex: ruby example.rb refund_account <transaction_id>
#
def example_refund_account(client, transaction_id)
  puts "** Running Example: Refund Account"

  # 1) user adds credit using credit card (through an intermediation partner - stripe)
  user_adds_credit_using_credit_card(client, transaction_id, "user2", "200", "stripe")

  # 1) intermediation partner confirms payment
  user_credit_added_successfully(client, transaction_id, "user2", "200", "stripe")

  # 2) now user has balance on his wallet, so he places an other
  purchase_with_balanced(client, transaction_id, "user2", "50", "referrer2", "publisher2", "distributor2", "government2", "whatever2")

  # 3) user regrets from his purchase, and gets refunded
  refund_purchase_to_user_account(client, transaction_id, "user2", "50", "referrer2", "publisher2", "distributor2", "government2", "whatever2")
end

# Example Refund Credit Card
# --------------------------
#
# 1) The user does not have enough balance, so he buys directly form his
#    credit card (through an intermediation partner - ex: stripe)
#
# 2) User 'cancel' purchase, and the amount is refunded to his credit card
#    (though the intermediation partner)
#
# Ex: ruby example.rb refund_credit_card <transaction_id>
#
def example_refund_credit_card(client, transaction_id)
  puts "** Running Example: Refund Credit Card"

  # 1) user makes a purchase from credit card
  purchase_with_credit_card(client, transaction_id, "user3", "300", "stripe", "referrer3", "publisher3", "distributor3", "government3", "whatever3")

  # 1) intermediation partner confirms payment
  credit_card_charge_success(client, transaction_id, "user3", "300", "stripe")

  # 2) user asks for refund
  refund_to_credit_card(client, transaction_id, "user3", "300", "stripe", "referrer3", "publisher3", "distributor3", "government3", "whatever3")
end

# Example Get Balances
# ----------------------
# Retrieve account balances (use example_full to generate data)
#
# Ex: ruby example.rb get_balances
#
def example_get_balances(client, transaction_id = nil)
  puts "** Running Example: Get Balances"

  get_account_balance(client, "user1"       , ["unused_balance"])
  get_account_balance(client, "referrer1"   , ["referrer", "accounts_payable"])
  get_account_balance(client, "referrer1"   , ["unused_balance"])
  get_account_balance(client, "publisher1"  , ["publisher", "accounts_payable"])
  get_account_balance(client, "distributor1", ["distributor", "accounts_payable"])
  get_account_balance(client, "government1" , ["government", "accounts_payable"])
  get_account_balance(client, "whatever1"   , ["whatever", "accounts_payable"])
end

# Example Get History
# ----------------------
# Retrieve account history (use example_full to generate data)
#
# Ex: ruby example.rb get_history <user_id>
#
def example_get_history(client, transaction_id = nil)
  puts "** Running Example: Get History"

  get_account_history(client, "user1", ["unused_balance"])
end


### Main

# instantiate client
client = PlugNPlay::Client.new(host, user, pass)

# get the example name from command line
example_name = ARGV[0]

# get transaction if from command line (if any)
transaction_id = ARGV[1] if ARGV.length > 1

# call the example method
send("example_#{example_name}", client, transaction_id)