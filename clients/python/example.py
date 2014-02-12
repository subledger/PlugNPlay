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

def goods_sold(client,transaction_id):
  print "* Goods Sold"
  print client.goods_sold(
    transaction_id=transaction_id, 
    buyer_id="buyer1@test.com",
    purchase_amount="150",
    revenue_amount="10",
    payables=[
      { "id": "stripe",                "amount": "9.25",   "role": "payment_gateway" },
      { "id": "referrer1@test.com",    "amount": "20.10",  "role": "referrer"        },
      { "id": "publisher1@test.com",   "amount": "40.90",  "role": "publisher"       },
      { "id": "distributor1@test.com", "amount": "55",     "role": "distributor"     },
      { "id": "taxes1@test.com",       "amount": "7.75",   "role": "government"      },
      { "id": "whatever1@test.com",    "amount": "7  " ,   "role": "whatever"        },
    ],
    reference_url="http://testingapi.com",
    description="API Python Client Goods Sold")

def charge_success(client,transaction_id):
  print "* Card Charge Success"
  print client.card_charge_success(
    transaction_id=transaction_id,
    buyer_id="buyer1@test.com",
    purchase_amount="150",
    intermediate_id="stripe",
    intermediate_role="payment_gateway",
    intermediation_fee="9.25",
    reference_url="http://testingapi.com/4",
    description="API Python Client Card Charge Success")

def payout_referrer(client,transaction_id):
  print "* Payout Referrer"
  print client.payout_referrer(
    transaction_id=transaction_id,
    account_id="referrer1@test.com",
    payout_amount="20.10",
    reference_url="http://testingapi.com",
    description="API Python Client Payout Referrer")

def payout_publisher(client,transaction_id):
  print "* Payout Publisher"
  print client.payout_publisher(
    transaction_id=transaction_id,
    account_id="publisher1@test.com",
    payout_amount="40.90",
    reference_url="http://testingapi.com",
    description="API Python Client Payout Publisher")

def payout_distributor(client,transaction_id):
  print "* Payout Distributor"
  print client.payout_distributor(
    transaction_id=transaction_id,
    account_id="distributor1@test.com",
    payout_amount="55",
    reference_url="http://testingapi.com",
    description="API Python Client Payout Distributor")

def payout_government(client,transaction_id):
  print "* Payout Government"
  print client.payout_government(
    transaction_id=transaction_id,
    account_id="taxes1@test.com",
    payout_amount="7.75",
    reference_url="http://testingapi.com",
    description="API Python Client Payout Government")

def payout_whatever(client,transaction_id):
  print "* Payout Whatever"
  print client.payout_whatever(
    transaction_id=transaction_id,
    account_id="whatever1@test.com",
    payout_amount="7",
    reference_url="http://testingapi.com",
    description="API Python Client Payout Whatever")

  # the above call is the same as:
  # client.payout(
  #   transaction_id=transaction_id,
  #   account_id="whatever1@test.com",
  #   account_role="whatever",
  #   payout_amount="7",
  #   reference_url="http://testingapi.com",
  #   description="API Python Client Payout ")

def main(href,user,pswd,transaction_id):  
    # instantiate the pnp client
    client = pnp.Client(href,user,pswd)

    # call the predefined methods
    #goods_sold(client,transaction_id)
    #charge_success(client,transaction_id)
    #payout_referrer(client,transaction_id)
    payout_publisher(client,transaction_id)
    payout_distributor(client,transaction_id)
    payout_government(client,transaction_id)
    payout_whatever(client,transaction_id)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Need transaction id"
        print "ex: python example.py 200"
    else:
        main(host,user,pswd,sys.argv[1])

