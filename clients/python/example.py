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

host = 'http://localhost:3000'
user = 'pnp'
pswd = 'pnp'

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

def user_adds_credit_using_credit_card(client,transaction_id):
  test = "* User Adds Credit Using Credit Card"
  tmin = time.time()

  selftest(test, tmin,
    client.user_adds_credit_using_credit_card(
      transaction_id=transaction_id, 
      user_id="user1@test.com",
      payment_amount="150",
      intermediate_id="stripe",
      intermediate_role="payment_gateway",
      intermediation_fee="10",
      reference_url="http://yourapp.com/user_adds_credit_using_credit_card/{0}".format(transaction_id),
      description="User Adds Credit Using Credit Card {0}: {1}".format(transaction_id, "user1@test.com")
    )
  )

def user_credit_added_successfully(client,transaction_id):
  test = "* User Credit Added Successfully"
  tmin = time.time()

  selftest(test, tmin,
    client.user_credit_added_successfully(
      transaction_id=transaction_id,
      user_id="user1@test.com",
      payment_amount="150",
      intermediate_id="stripe",
      intermediate_role="payment_gateway",
      intermediation_fee="10",
      reference_url="http://yourapp.com/user_credit_added_successfully/{0}".format(transaction_id),
      description="User Credit Added Successfully {0}: {1}".format(transaction_id, "user1@test.com")
    )
  )

def purchase_with_balanced(client,transaction_id):
  test = "* Purchase With Balance"
  tmin = time.time()

  selftest(test, tmin,
    client.purchase_with_balance(
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
      description="Purchase With Balance {0}: {1}".format(transaction_id, "user1@test.com")
    )
  )

def refund_purchase_to_user_account(client,transaction_id):
  test = "* Refund Purchase to User Account"
  tmin = time.time()

  selftest(test, tmin,
    client.purchase_with_balance(
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
      description="Purchase With Balance {0}: {1}".format(transaction_id, "user1@test.com")
    )
  )

  tmin = time.time()
  selftest(test, tmin,
    client.refund_purchase_to_user_account(
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
      description="Refund Purchase to User Account {0}: {1}".format(transaction_id, "user1@test.com")
    )
  )


### Drop-in user (not signed in)

def purchase_with_credit_card(client,transaction_id):
  test = "* Purchase With Credit Card"
  tmin = time.time()

  selftest(test, tmin,
    client.purchase_with_credit_card(
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
      description="Purchase With Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com")
    )
  )

def credit_card_charge_success(client,transaction_id):
  test = "* Credit Card Charge Success"
  tmin = time.time()

  selftest(test, tmin,
    client.credit_card_charge_success(
      transaction_id=transaction_id, 
      user_id="nonuser1@test.com",
      purchase_amount="100",
      intermediate_id="stripe",
      intermediate_role="payment_gateway",
      intermediation_fee="10",
      reference_url="http://yourapp.com/credit_card_charge_success/{0}".format(transaction_id),
      description="Credit Card Charge Success {0}: {1}".format(transaction_id, "nonuser1@test.com")
    )
  )

def refund_to_credit_card(client,transaction_id):
  name = "* Refund to Credit Card"

  test = name + ' purchase'
  tmin = time.time()

  selftest(test, tmin,
    client.purchase_with_credit_card(
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
      description="Purchase With Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com")
    )
  )

  test = name + ' commit'
  tmin = time.time()

  selftest(test, tmin,
    client.credit_card_charge_success(
      transaction_id=transaction_id, 
      user_id="nonuser1@test.com",
      purchase_amount="7",
      intermediate_id="stripe",
      intermediate_role="payment_gateway",
      intermediation_fee="1",
      reference_url="http://yourapp.com/credit_card_charge_success/{0}".format(transaction_id),
      description="Credit Card Charge Success {0}: {1}".format(transaction_id, "nonuser1@test.com")
    )
  )

  test = name + ' refund'
  tmin = time.time()

  selftest(test, tmin,
    client.refund_to_credit_card(
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
      description="Refund to Credit Card {0}: {1}".format(transaction_id, "nonuser1@test.com")
    )
  )

def payout_referrer(client,transaction_id):
  test = "* Payout Referrer"
  tmin = time.time()

  selftest(test, tmin,
    client.payout_referrer(
      transaction_id=transaction_id,
      account_id="referrer1@test.com",
      payout_amount="30.10",
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout Reffer {0}: {1}".format(transaction_id, "reffer1@test.com")
    )
  )

def payout_publisher(client,transaction_id):
  test = "* Payout Publisher"
  tmin = time.time()

  selftest(test, tmin,
    client.payout_publisher(
      transaction_id=transaction_id,
      account_id="publisher1@test.com",
      payout_amount="81.80",
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout Publisher {0}: {1}".format(transaction_id, "publisher1@test.com")
    )
  )

def payout_distributor(client,transaction_id):
  test = "* Payout Distributor"
  tmin = time.time()

  selftest(test, tmin,
    client.payout_distributor(
      transaction_id=transaction_id,
      account_id="distributor1@test.com",
      payout_amount="20",
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout Distributor {0}: {1}".format(transaction_id, "distributor1@test.com")
    )
  )

def payout_government(client,transaction_id):
  test = "* Payout Government"
  tmin = time.time()

  selftest(test, tmin,
    client.payout_government(
      transaction_id=transaction_id,
      account_id="taxes1@test.com",
      payout_amount="19",
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout Government {0}: {1}".format(transaction_id, "taxes1@test.com")
    )
  )

def payout_whatever(client,transaction_id):
  test = "* Payout Whatever"
  tmin = time.time()

  selftest(test, tmin,
    client.payout_whatever(
      transaction_id=transaction_id,
      account_id="whatever1@test.com",
      payout_amount="20",
      reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
      description="Payout Whatever {0}: {1}".format(transaction_id, "whatever1@test.com")
    )
  )

  # the above call is the same as:
  # client.payout(
  #   transaction_id=transaction_id,
  #   account_id="whatever1@test.com",
  #   account_role="whatever",
  #   payout_amount="20",
  #   reference_url="http://yourapp.com/payout/{0}".format(transaction_id),
  #   description="Payout Whatever {0}: {1}".format(transaction_id, "whatever1@test.com"))

def get_balance(client, test, user_id, sufixes):
  tmin = time.time()

  # time must be in iso 8601 format
  now = datetime.datetime.now().isoformat()

  on_response = lambda j: (
    "{0} ({1})".format(
      j['response']['value']['amount'], j['response']['value']['type']
    )
  )

  selftest(test, tmin,
    client.get_user_balance(
      user_id=user_id,
      sufixes=sufixes,
      at=now
    ),
    on_response
  )

def get_user_balance(client):
  test = "* Get User Balance"
  get_balance(client, test, "user1@test.com", ["unused_balance"])

def get_referrer_balance(client):
  test = "* Get Referrer Balance"
  get_balance(client, test, "referrer1@test.com", ["referrer", "accounts_payable"])

def get_publisher_balance(client):
  test = "* Get Publisher Balance"
  get_balance(client, test, "publisher1@test.com", ["publisher", "accounts_payable"])

def get_distributor_balance(client):
  test = "* Get Distributor Balance"
  get_balance(client, test, "distributor1@test.com", ["distributor", "accounts_payable"])

def get_government_balance(client):
  test = "* Get Government Balance"
  get_balance(client, test, "taxes1@test.com", ["government", "accounts_payable"])

def get_whatever_balance(client):
  test = "* Get Whatever Balance"
  get_balance(client, test, "whatever1@test.com", ["whatever", "accounts_payable"])

def get_user_history(client):
  print "* Get User History"
  tmin = time.time()

  # time must be in iso 8601 format
  now = datetime.datetime.now().isoformat()

  page_id = None
  message = "No history available"

  while True:
    response_str = client.get_user_history(
      user_id="user1@test.com",
      sufixes=["unused_balance"],
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


def balances(href,user,pswd):  
    tmin = time.time()

    # instantiate the pnp client
    client = pnp.Client(href,user,pswd)

    # get user account balance information
    get_user_balance(client)
    get_referrer_balance(client)
    get_publisher_balance(client)
    get_distributor_balance(client)
    get_government_balance(client)
    get_whatever_balance(client)

    # get a user account history
    get_user_history(client)

    elap = elapsed(tmin,time.time())
    print 'Total Elapsed: {}'.format(elap)

def transactions(href,user,pswd,transaction_id):  
    tmin = time.time()

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
    payout_publisher(client,int(transaction_id)*100)
    payout_distributor(client,int(transaction_id)*1000)
    payout_government(client,int(transaction_id)*10000)
    payout_whatever(client,int(transaction_id)*100000)

    elap = elapsed(tmin,time.time())
    print 'Total Elapsed: {}'.format(elap)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        balances(host, user, pswd)
    else:
        transactions(host, user, pswd, sys.argv[1])
