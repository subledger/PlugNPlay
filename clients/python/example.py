#!/usr/bin/python

import sys
import pnp

if len(sys.argv) < 2:
  print "Need transaction id"
  print "ex: python example.py 200"
  exit()


client = pnp.Client("http://localhost:3000", "pnp", "password")
transaction_id = sys.argv[1]

print "* Goods Sold"
print client.goods_sold(
  transaction_id=transaction_id, 
  buyer_id="buyer1@test.com",
  purchase_amount="100",
  referrer_id="referrer1@test.com",
  referrer_amount="25",
  publisher_id="publisher1@test.com",
  publisher_amount="25",
  distributor_id="distributor1@test.com",
  distributor_amount="25",
  reference_url="http://testingapi.com",
  description="API Python Client Goods Sold"
)

print "* Card Charge Success"
print client.card_charge_success(
  transaction_id=transaction_id,
  buyer_id="buyer1@test.com",
  purchase_amount="100",
  payment_fee="10",
  reference_url="http://testingapi.com/4",
  description="API Python Client Card Charge Success"
)

print "* Payout Referrer"
print client.payout_referrer(
  transaction_id=transaction_id,
  referrer_id="referrer1@test.com",
  payout_amount="25",
  reference_url="http://testingapi.com",
  description="API Python Client Payout Referrer"
)

print "* Payout Publisher"
print client.payout_publisher(
  transaction_id=transaction_id,
  publisher_id="publisher@test.com",
  payout_amount="25",
  reference_url="http://testingapi.com",
  description="API Python Client Payout Publisher"
)

print "* Payout Distributor"
print client.payout_distributor(
  transaction_id=transaction_id,
  distributor_id="distributor1@test.com",
  payout_amount="25",
  reference_url="http://testingapi.com",
  description="API Python Client Payout Distributor"
)
