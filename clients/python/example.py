#!/usr/bin/python
#
# Example Subledger PnP command line client.
#
# Usage:
#  python example.py <transaction_id>
#
# Author: Alexandre Michetti Manduca <alex@subledger.com>
#
# Contributors:
#   Eric W. Brown <ebrow@techmart.com>
#

import sys
import pnp

host = 'http://localhost:3000'
user = 'pnp'
pswd = 'pnp'

def user_adds_credit_using_credit_card(client,transaction_id):
  print "* User Adds Credit Using Credit Card"
  print client.user_adds_credit_using_credit_card(
    transaction_id=transaction_id, 
    user_id="user1@test.com",
    payment_amount="150",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="10",
    reference_url="http://yourapp.com/user_adds_credit_using_credit_card/{0}".format(transaction_id),
    description="User Adds Credit Using Credit Card {0}: {1}".format(transaction_id, "user1@test.com"))

def user_credit_added_successfully(client,transaction_id):
  print "* User Credit Added Successfully"
  print client.user_credit_added_successfully(
    transaction_id=transaction_id,
    user_id="user1@test.com",
    payment_amount="150",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="10",
    reference_url="http://yourapp.com/user_credit_added_successfully/{0}".format(transaction_id),
    description="User Credit Added Successfully {0}: {1}".format(transaction_id, "user1@test.com"))

def purchase_with_balanced(client,transaction_id):
  print "* Purchase With Balance"
  print client.purchase_with_balance(
    transaction_id=transaction_id, 
    user_id="user1@test.com",
    purchase_amount="100",
    revenue_amount="10",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "20.10",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "40.90",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "10"   ,  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "9"    ,  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "10"   ,  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/purchase_with_balance/{0}".format(transaction_id),
    description="Purchase With Balance {0}: {1}".format(transaction_id, "user1@test.com"))

def refund_purchase_to_user_account(client,transaction_id):
  print "* Refund Purchase to User Account"
  print client.purchase_with_balance(
    transaction_id=transaction_id, 
    user_id="user1@test.com",
    purchase_amount="6",
    revenue_amount="1",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "1",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "1",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "1",  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "1",  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "1",  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/purchase_with_balance/{0}".format(transaction_id),
    description="Purchase With Balance {0}: {1}".format(transaction_id, "user1@test.com"))

  print client.refund_purchase_to_user_account(
    transaction_id=transaction_id, 
    user_id="user1@test.com",
    refund_amount="6",
    revenue_amount="1",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "1",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "1",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "1",  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "1",  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "1",  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/refund_purchase_to_user_account/{0}".format(transaction_id),
    description="Refund Purchase to User Account {0}: {1}".format(transaction_id, "user1@test.com"))


### Drop-in user (not signed in)

def purchase_with_credit_card(client,transaction_id):
  print "* Purchase With Credit Card"
  print client.purchase_with_credit_card(
    transaction_id=transaction_id, 
    user_id="nonuser1@test.com",
    purchase_amount="100",
    revenue_amount="10",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="10",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "10.10",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "40.90",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "10"   ,  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "9"    ,  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "10"   ,  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/purchase_with_credit_card/{0}".format(transaction_id),
    description="Purchase With Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com"))

def credit_card_charge_success(client,transaction_id):
  print "* Credit Card Charge Success"
  print client.credit_card_charge_success(
    transaction_id=transaction_id, 
    user_id="nonuser1@test.com",
    purchase_amount="100",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="10",
    reference_url="http://yourapp.com/credit_card_charge_success/{0}".format(transaction_id),
    description="Credit Card Charge Success {0}: {1}".format(transaction_id, "nonuser1@test.com"))

def refund_to_credit_card(client,transaction_id):
  print "* Refund to Credit Card"
  print client.purchase_with_credit_card(
    transaction_id=transaction_id, 
    user_id="nonuser1@test.com",
    purchase_amount="7",
    revenue_amount="1",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="1",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "1",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "1",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "1",  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "1",  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "1",  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/purchase_with_credit_card/{0}".format(transaction_id),
    description="Purchase With Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com"))

  print client.credit_card_charge_success(
    transaction_id=transaction_id, 
    user_id="nonuser1@test.com",
    purchase_amount="7",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="1",
    reference_url="http://yourapp.com/credit_card_charge_success/{0}".format(transaction_id),
    description="Credit Card Charge Success {0}: {1}".format(transaction_id, "nonuser1@test.com"))

  print client.refund_to_credit_card(
    transaction_id=transaction_id, 
    user_id="nonuser1@test.com",
    refund_amount="7",
    revenue_amount="1",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="1",
    payables=[
      { "id": "referrer1@test.com"   , "amount": "1",  "role": "referrer"    },
      { "id": "publisher1@test.com"  , "amount": "1",  "role": "publisher"   },
      { "id": "distributor1@test.com", "amount": "1",  "role": "distributor" },
      { "id": "taxes1@test.com"      , "amount": "1",  "role": "government"  },
      { "id": "whatever1@test.com"   , "amount": "1",  "role": "whatever"    },
    ],
    reference_url="http://yourapp.com/refund_to_credit_card/{0}".format(transaction_id),
    description="Refund to Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com"))

def payout_referrer(client,transaction_id):
  print "* Payout Referrer"
  print client.payout_referrer(
    transaction_id=transaction_id,
    account_id="referrer1@test.com",
    payout_amount="30.10",
    reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
    description="Payout Reffer {0}: {1}".format(transaction_id, "reffer1@test.com"))

def payout_publisher(client,transaction_id):
  print "* Payout Publisher"
  print client.payout_publisher(
    transaction_id=transaction_id,
    account_id="publisher1@test.com",
    payout_amount="81.80",
    reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
    description="Payout Publisher {0}: {1}".format(transaction_id, "publisher1@test.com"))

def payout_distributor(client,transaction_id):
  print "* Payout Distributor"
  print client.payout_distributor(
    transaction_id=transaction_id,
    account_id="distributor1@test.com",
    payout_amount="20",
    reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
    description="Payout Distributor {0}: {1}".format(transaction_id, "distributor1@test.com"))

def payout_government(client,transaction_id):
  print "* Payout Government"
  print client.payout_government(
    transaction_id=transaction_id,
    account_id="taxes1@test.com",
    payout_amount="19",
    reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
    description="Payout Government {0}: {1}".format(transaction_id, "taxes1@test.com"))

def payout_whatever(client,transaction_id):
  print "* Payout Whatever"
  print client.payout_whatever(
    transaction_id=transaction_id,
    account_id="whatever1@test.com",
    payout_amount="20",
    reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
    description="Payout Whatever {0}: {1}".format(transaction_id, "whatever1@test.com"))

  # the above call is the same as:
  # client.payout(
  #   transaction_id=transaction_id,
  #   account_id="whatever1@test.com",
  #   account_role="whatever",
  #   payout_amount="20",
  #   reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
  #   description="Payout Whatever {0}: {1}".format(transaction_id, "whatever1@test.com"))

def main(href,user,pswd,transaction_id):  
    # instantiate the pnp client
    client = pnp.Client(href,user,pswd)

    # methods for users with an account (wallet style)
    user_adds_credit_using_credit_card(client,transaction_id)
    user_credit_added_successfully(client,transaction_id)
    purchase_with_balanced(client,transaction_id)
    refund_purchase_to_user_account(client,int(transaction_id)+100)

    # methods for drop-in users (not signed up)
    purchase_with_credit_card(client,transaction_id)
    credit_card_charge_success(client,transaction_id)
    refund_to_credit_card(client,int(transaction_id)+100)

    # payouts 
    payout_referrer(client,transaction_id)
    payout_publisher(client,int(transaction_id)+100)
    payout_distributor(client,int(transaction_id)+101)
    payout_government(client,int(transaction_id)+102)
    payout_whatever(client,int(transaction_id)+103)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Need transaction id"
        print "ex: python example.py 200"
    else:
        main(host,user,pswd,sys.argv[1])

