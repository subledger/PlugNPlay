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
import time
import json
import datetime
from decimal import *

host   = 'http://localhost:3000'
user   = 'pnp'
passwd = 'pnp'

def calc_intermediate_amount(total):
  return str(Decimal(total) * Decimal('0.01'))

def calc_referrer_amount(total):
  return str(Decimal(total) * Decimal('0.1'))

def calc_publisher_amount(total):
  return str(Decimal(total) * Decimal('0.1'))

def calc_distributor_amount(total):
  return str(Decimal(total) * Decimal('0.1'))

def calc_government_amount(total):
  return str(Decimal(total) * Decimal('0.05'))

def calc_whatever_amount(total):
  return str(Decimal(total) * Decimal('0.01'))

### Util method to print elapsed time
def elapsed(tmin, tmax):
  " elapsed time from tmin to tmax, in reasonable format "

  if tmax < tmin:
    return '-' + elapsed(tmax, tmin)

  secs = tmax - tmin
  ss = int(secs)

  if ss < 60:
    ms = int(secs*1000)
    return '%d.%03d' % divmod(ms, 1000)

  if ss < 3600:
    return u'%d:%02d' % divmod(ss, 60)

  (hh, ss) = divmod(ss, 3600)
  (mm, ss) = divmod(ss, 60)

  return '%d:%02d:%02d' % (hh, mm, ss)

### Util method to handle results
def selftest(name, tmin, valu, on_response=None):
  " report name of test, elapsed time and if the call was successful or not "

  tmax = time.time()
  elap = elapsed(tmin, tmax)

  # parsing error implies failure
  try:
    text = unicode(valu)
    defs = json.loads(text)

  except ValueError:
    defs = {}

  rval = defs.get('response', 'error')
  good = (rval != 'error')

  if good:
    if on_response:
      print '{} ({}) - {}'.format(name, elap, on_response(defs))
    else:
      print '{} ({}) - {}'.format(name, elap, good)
  else:
    print '{} ({}) - {}'.format(name, elap, defs.get('error_description'))

  return good


### Actual app method calls

def user_adds_credit_using_credit_card(client, transaction_id, user_id, payment_amount, intermediate_id):
  test = "* User Adds Credit Using Credit Card"
  tmin = time.time()

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(payment_amount)

  # make the api call
  selftest(test, tmin,

    client.user_adds_credit_using_credit_card(
      transaction_id=transaction_id, 
      user_id=user_id,
      payment_amount=payment_amount,
      intermediate_id=intermediate_id,
      intermediate_role="payment_gateway",
      intermediation_fee=intermediate_amount,
      reference_url="http://yourapp.com/user_adds_credit_using_credit_card/{0}".format(transaction_id),
      description="User Adds Credit Using Credit Card {0}: {1}".format(transaction_id, user_id)
    )

  )

def user_credit_added_successfully(client, transaction_id, user_id, payment_amount, intermediate_id):
  test = "* User Credit Added Successfully"
  tmin = time.time()

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(payment_amount)

  # make the api call
  selftest(test, tmin,

    client.user_credit_added_successfully(
      transaction_id=transaction_id,
      user_id=user_id,
      payment_amount=payment_amount,
      intermediate_id=intermediate_id,
      intermediate_role="payment_gateway",
      intermediation_fee=intermediate_amount,
      reference_url="http://yourapp.com/user_credit_added_successfully/{0}".format(transaction_id),
      description="User Credit Added Successfully {0}: {1}".format(transaction_id, user_id)
    )

  )

def purchase_with_balanced(client, transaction_id, user_id, purchase_amount, referrer_id, publisher_id, distributor_id, government_id, whatever_id):
  test = "* Purchase With Balance"
  tmin = time.time()

  # calculate each payable amount
  referrer_amount     = calc_referrer_amount(purchase_amount)
  publisher_amount    = calc_publisher_amount(purchase_amount)
  distributor_amount  = calc_distributor_amount(purchase_amount)
  government_amount   = calc_government_amount(purchase_amount)
  whatever_amount     = calc_whatever_amount(purchase_amount)

  # calculate reveneue (remainder)
  revenue_amount  = Decimal(purchase_amount)
  revenue_amount -= Decimal(referrer_amount)
  revenue_amount -= Decimal(publisher_amount)
  revenue_amount -= Decimal(distributor_amount)
  revenue_amount -= Decimal(government_amount)
  revenue_amount -= Decimal(whatever_amount)
  revenue_amount  = str(revenue_amount)

  # make the api call
  selftest(test, tmin,
    client.purchase_with_balance(
      transaction_id=transaction_id, 
      user_id=user_id,
      purchase_amount=purchase_amount,
      revenue_amount=revenue_amount,
      payables=[
        { "id": referrer_id   , "amount": referrer_amount   ,  "role": "referrer"    },
        { "id": publisher_id  , "amount": publisher_amount  ,  "role": "publisher"   },
        { "id": distributor_id, "amount": distributor_amount,  "role": "distributor" },
        { "id": government_id , "amount": government_amount ,  "role": "government"  },
        { "id": whatever_id   , "amount": whatever_amount   ,  "role": "whatever"    },
      ],
      reference_url="http://yourapp.com/purchase_with_balance/{0}".format(transaction_id),
      description="Purchase With Balance {0}: {1}".format(transaction_id, user_id)
    )
  )

def refund_purchase_to_user_account(client, transaction_id, user_id, refund_amount, referrer_id, publisher_id, distributor_id, government_id, whatever_id):
  test = "* Refund Purchase to User Account"
  tmin = time.time()

  # calculate each payable amount
  referrer_amount     = calc_referrer_amount(refund_amount)
  publisher_amount    = calc_publisher_amount(refund_amount)
  distributor_amount  = calc_distributor_amount(refund_amount)
  government_amount   = calc_government_amount(refund_amount)
  whatever_amount     = calc_whatever_amount(refund_amount)

  # calculate reveneue (remainder)
  revenue_amount  = Decimal(refund_amount)
  revenue_amount -= Decimal(referrer_amount)
  revenue_amount -= Decimal(publisher_amount)
  revenue_amount -= Decimal(distributor_amount)
  revenue_amount -= Decimal(government_amount)
  revenue_amount -= Decimal(whatever_amount)
  revenue_amount  = str(revenue_amount)

  # make the api call
  selftest(test, tmin,
    client.refund_purchase_to_user_account(
      transaction_id=transaction_id, 
      user_id=user_id,
      refund_amount=refund_amount,
      revenue_amount=revenue_amount,
      payables=[
        { "id": referrer_id   , "amount": referrer_amount   ,  "role": "referrer"    },
        { "id": publisher_id  , "amount": publisher_amount  ,  "role": "publisher"   },
        { "id": distributor_id, "amount": distributor_amount,  "role": "distributor" },
        { "id": government_id , "amount": government_amount ,  "role": "government"  },
        { "id": whatever_id   , "amount": whatever_amount   ,  "role": "whatever"    },
      ],
      reference_url="http://yourapp.com/refund_purchase_to_user_account/{0}".format(transaction_id),
      description="Refund Purchase to User Account {0}: {1}".format(transaction_id, user_id)
    )
  )

def transfer_to_external_account(client, transaction_id, user_id, transfer_amount, intermediate_id):
  test = "* Transfer to External Account"
  tmin = time.time()

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(transfer_amount)

  # make the api call
  selftest(test, tmin,
      client.transfer_to_external_account(
        transaction_id=transaction_id,
        user_id=user_id,
        transfer_amount=transfer_amount,
        intermediate_id=intermediate_id,
        intermediate_role="payment_gateway",
        intermediation_fee=intermediate_amount,
        reference_url="http://yourapp.com/transfer_to_external_account/{0}".format(transaction_id),
        description="Transfer to External Account {0}: {1}".format(transaction_id, user_id)
      )
  )

def transfer_to_external_account_successfull(client, transaction_id, user_id, transfer_amount, intermediate_id):
  test = "* Transfer to External Account Successfull"
  tmin = time.time()

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(transfer_amount)

  # make the api call
  selftest(test, tmin,
      client.transfer_to_external_account_successfull(
        transaction_id=transaction_id,
        user_id=user_id,
        transfer_amount=transfer_amount,
        intermediate_id=intermediate_id,
        intermediate_role="payment_gateway",
        intermediation_fee=intermediate_amount,
        reference_url="http://yourapp.com/transfer_to_external_account_successfull/{0}".format(transaction_id),
        description="Transfer to External Account Successfull{0}: {1}".format(transaction_id, user_id)
      )
  )

def transfer_to_wallet(client, transaction_id, user_id, user_role, transfer_amount):
  test = "* Transfer to Wallet"
  tmin = time.time()

  # make the api call
  selftest(test, tmin,
      client.transfer_to_wallet(
        transaction_id=transaction_id,
        user_id=user_id,
        user_role=user_role,
        transfer_amount=transfer_amount,
        reference_url="http://yourapp.com/transfer_to_wallet/{0}".format(transaction_id),
        description="Transfer to Wallet {0}: {1}".format(transaction_id, user_id)
      )
  )


def purchase_with_credit_card(client, transaction_id, user_id, purchase_amount, intermediate_id, referrer_id, publisher_id, distributor_id, government_id, whatever_id):
  test = "* Purchase With Credit Card"
  tmin = time.time()

  # calculate each payable amount
  intermediate_amount = calc_intermediate_amount(purchase_amount)
  referrer_amount     = calc_referrer_amount(purchase_amount)
  publisher_amount    = calc_publisher_amount(purchase_amount)
  distributor_amount  = calc_distributor_amount(purchase_amount)
  government_amount   = calc_government_amount(purchase_amount)
  whatever_amount     = calc_whatever_amount(purchase_amount)

  # calculate reveneue (remainder)
  revenue_amount  = Decimal(purchase_amount)
  revenue_amount -= Decimal(intermediate_amount)
  revenue_amount -= Decimal(referrer_amount)
  revenue_amount -= Decimal(publisher_amount)
  revenue_amount -= Decimal(distributor_amount)
  revenue_amount -= Decimal(government_amount)
  revenue_amount -= Decimal(whatever_amount)
  revenue_amount  = str(revenue_amount)

  # make the api call
  selftest(test, tmin,
    client.purchase_with_credit_card(
      transaction_id=transaction_id, 
      user_id=user_id,
      purchase_amount=purchase_amount,
      revenue_amount=revenue_amount,
      intermediate_id=intermediate_id,
      intermediate_role="payment_gateway",
      intermediation_fee=intermediate_amount,
      payables=[
        { "id": referrer_id   , "amount": referrer_amount   ,  "role": "referrer"    },
        { "id": publisher_id  , "amount": publisher_amount  ,  "role": "publisher"   },
        { "id": distributor_id, "amount": distributor_amount,  "role": "distributor" },
        { "id": government_id , "amount": government_amount ,  "role": "government"  },
        { "id": whatever_id   , "amount": whatever_amount   ,  "role": "whatever"    },
      ],
      reference_url="http://yourapp.com/purchase_with_credit_card/{0}".format(transaction_id),
      description="Purchase With Credit Card {0}: {1}".format(transaction_id, user_id)
    )
  )

def credit_card_charge_success(client, transaction_id, user_id, purchase_amount, intermediate_id):
  test = "* Credit Card Charge Success"
  tmin = time.time()

  # calculate intermediation fee
  intermediate_amount = calc_intermediate_amount(purchase_amount)

  # make the api call
  selftest(test, tmin,
    client.credit_card_charge_success(
      transaction_id=transaction_id, 
      user_id=user_id,
      purchase_amount=purchase_amount,
      intermediate_id=intermediate_id,
      intermediate_role="payment_gateway",
      intermediation_fee=intermediate_amount,
      reference_url="http://yourapp.com/credit_card_charge_success/{0}".format(transaction_id),
      description="Credit Card Charge Success {0}: {1}".format(transaction_id, user_id)
    )
  )

def refund_to_credit_card(client, transaction_id, user_id, refund_amount, intermediate_id, referrer_id, publisher_id, distributor_id, government_id, whatever_id):
  test = "* Refund to Credit Card"
  tmin = time.time()

  # calculate each payable amount
  intermediate_amount = calc_intermediate_amount(refund_amount)
  referrer_amount     = calc_referrer_amount(refund_amount)
  publisher_amount    = calc_publisher_amount(refund_amount)
  distributor_amount  = calc_distributor_amount(refund_amount)
  government_amount   = calc_government_amount(refund_amount)
  whatever_amount     = calc_whatever_amount(refund_amount)

  # calculate reveneue (remainder)
  revenue_amount  = Decimal(refund_amount)
  revenue_amount -= Decimal(intermediate_amount)
  revenue_amount -= Decimal(referrer_amount)
  revenue_amount -= Decimal(publisher_amount)
  revenue_amount -= Decimal(distributor_amount)
  revenue_amount -= Decimal(government_amount)
  revenue_amount -= Decimal(whatever_amount)
  revenue_amount  = str(revenue_amount)

  # make the api call
  selftest(test, tmin,
    client.refund_to_credit_card(
      transaction_id=transaction_id, 
      user_id=user_id,
      refund_amount=refund_amount,
      revenue_amount=revenue_amount,
      intermediate_id=intermediate_id,
      intermediate_role="payment_gateway",
      intermediation_fee=intermediate_amount,
      payables=[
        { "id": referrer_id   , "amount": referrer_amount   ,  "role": "referrer"    },
        { "id": publisher_id  , "amount": publisher_amount  ,  "role": "publisher"   },
        { "id": distributor_id, "amount": distributor_amount,  "role": "distributor" },
        { "id": government_id , "amount": government_amount ,  "role": "government"  },
        { "id": whatever_id   , "amount": whatever_amount   ,  "role": "whatever"    },
      ],
      reference_url="http://yourapp.com/refund_to_credit_card/{0}".format(transaction_id),
      description="Refund to Credit Card {0}: {1}".format(transaction_id, user_id)
    )
  )

def payout(client, transaction_id, account_id, account_role, payout_amount):
  test = "* Payout {0}: {1}".format(account_role, account_id)
  tmin = time.time()

  # make the api call
  selftest(test, tmin,
    client.payout(
      transaction_id=transaction_id,
      account_id=account_id,
      account_role=account_role,
      payout_amount=payout_amount,
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout {0}: {1}".format(transaction_id, account_id)
    )
  )

def get_account_balance(client, user_id, sufixes):
  test = "* Get Account Balance {0}".format(user_id)
  tmin = time.time()

  # time must be in iso 8601 format
  now = datetime.datetime.now().isoformat()

  # lambda to format the command line response
  on_response = lambda j: (
    "{0} ({1})".format(
      j['response']['value']['amount'], j['response']['value']['type']
    )
  )

  # make the api call
  selftest(test, tmin,
    client.get_user_balance(
      user_id=user_id,
      sufixes=sufixes,
      at=now
    ),
    on_response
  )

def get_account_history(client, user_id, sufixes):
  print "* Get Account History {0}".format(user_id)
  tmin = time.time()

  # time must be in iso 8601 format
  now = datetime.datetime.now().isoformat()

  page_id = None
  message = "No history available"

  while True:
    response_str = client.get_user_history(
      user_id=user_id,
      sufixes=sufixes,
      date=now,
      order="desc",
      page_id=page_id,
      per_page=5
    )

    # parsing error implies failure
    try:
      text = unicode(response_str)
      defs = json.loads(text)

    except ValueError:
      defs = {}

    if defs['count'] == 0:
      # stop iteration
      message = "No history available"
      break
    else:
      # print the account history
      for line in iter(defs['response']):
        print "{0} -> {1} ({2})".format(
            line['description'],
            line['value']['amount'],
            line['value']['type']
        )

      # get the next page id
      page_id = defs['response'][-1]['id']

  elap = elapsed(tmin, time.time())
  print '({}) - {}'.format(elap, True)


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
def example_full(client, transaction_id):
    print "** Running Example: Full"

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
    payout(client, str(int(transaction_id)+100), "distributor1", "distributor", "10")
    payout(client, str(int(transaction_id)+1000), "government1", "government", "10")
    payout(client, str(int(transaction_id)+10000), "whatever1", "whatever", "1")

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
def example_refund_account(client, transaction_id):
    print "** Running Example: Refund Account"

    # 1) user adds credit using credit card (through an intermediation partner - stripe)
    user_adds_credit_using_credit_card(client, transaction_id, "user2", "200", "stripe")

    # 1) intermediation partner confirms payment
    user_credit_added_successfully(client, transaction_id, "user2", "200", "stripe")

    # 2) now user has balance on his wallet, so he places an other
    purchase_with_balanced(client, transaction_id, "user2", "50", "referrer2", "publisher2", "distributor2", "government2", "whatever2")

    # 3) user regrets from his purchase, and gets refunded
    refund_purchase_to_user_account(client, transaction_id, "user2", "50", "referrer2", "publisher2", "distributor2", "government2", "whatever2")

# Example Refund Account
# ----------------------
#
# 1) The user does not have enough balance, so he buys directly form his
#    credit card (through an intermediation partner - ex: stripe)
#
# 2) User 'cancel' purchase, and the amount is refunded to his credit card
#    (though the intermediation partner)
#
def example_refund_credit_card(client, transaction_id):
    print "** Running Example: Refund Credit Card"

    # 1) user makes a purchase from credit card
    purchase_with_credit_card(client, transaction_id, "user3", "300", "stripe", "referrer3", "publisher3", "distributor3", "government3", "whatever3")

    # 1) intermediation partner confirms payment
    credit_card_charge_success(client, transaction_id, "user3", "300", "stripe")

    # 2) user asks for refund
    refund_to_credit_card(client, transaction_id, "user3", "300", "stripe", "referrer3", "publisher3", "distributor3", "government3", "whatever3")

# Example Get Balances
# ----------------------
# Retrieve account balances (use example_full to generate data)
#
def example_get_balances(client, transaction_id = None):
    print "** Running Example: Get Balances"

    get_account_balance(client, "user1"       , ["unused_balance"])
    get_account_balance(client, "referrer1"   , ["referrer", "accounts_payable"])
    get_account_balance(client, "referrer1"   , ["unused_balance"])
    get_account_balance(client, "publisher1"  , ["publisher", "accounts_payable"])
    get_account_balance(client, "distributor1", ["distributor", "accounts_payable"])
    get_account_balance(client, "government1" , ["government", "accounts_payable"])
    get_account_balance(client, "whatever1"   , ["whatever", "accounts_payable"])

# Example Get History
# ----------------------
# Retrieve account history (use example_full to generate data)
#
def example_get_history(client, transaction_id = None):
    print "** Running Example: Get History"

    get_account_history(client, "user1", ["unused_balance"])


### Main
if __name__ == '__main__':
    # get start time
    tmin = time.time()

    # instantiate the pnp client
    client = pnp.Client(host, user, passwd)

    # call the example
    method_name = "example_{0}".format(sys.argv[1])

    transaction_id = None
    if len(sys.argv) > 2:
      transaction_id = sys.argv[2]

    method = globals()[method_name]
    method(client, transaction_id)

    # print elapsed time
    elap = elapsed(tmin,time.time())
    print 'Total Elapsed: {}'.format(elap)
