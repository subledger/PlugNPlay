class SubledgerService < ApplicationService
  knows_accounting

  def goods_sold(data)
    data = data.symbolize_keys

    # transaction data
    transaction_id  = data[:transaction_id]
    buyer_id        = data[:buyer_id]
    purchase_amount = BigDecimal.new data[:purchase_amount]
    revenue_amount  = BigDecimal.new data[:revenue_amount]
    payables        = data[:payables]
    reference_url   = data[:reference_url]
    description     = data[:description]

    # journal entry lines
    lines = []

    # buyer line
    buyer_ar = account_receivable buyer_id, role: :buyer
    lines.push debit_line(account: buyer_ar, amount: purchase_amount)

    # revenue line
    revenue = global_account :revenue
    lines.push credit_line(account: revenue, amount: revenue_amount)

    # lines for each payable
    payables.each do |payable|
      payable = payable.symbolize_keys

      # line attributes
      account_id = payable[:id]
      role = payable[:role].to_sym
      amount = BigDecimal.new payable[:amount]

      # get a category for this role
      category(role, normal_balance: credit)

      # attach the category to report
      attach_category_to_report role, :balance, parent_category_id: :accounts_payable

      # create the account and attach the category
      entity_account_payable = account_payable account_id, role: role, category: role

      lines.push credit_line(account: entity_account_payable, amount: amount)
    end

    # post the lines
    return post_transaction :goods_sold, transaction_id, lines, {
      description: description,
      reference_url: reference_url
    }
  end

  def card_charge_success(data)
    data = data .symbolize_keys
  
    # transaction data  
    transaction_id  = data[:transaction_id]
    buyer_id        = data[:buyer_id]
    purchase_amount = BigDecimal.new data[:purchase_amount]
    payment_fee     = BigDecimal.new data[:payment_fee]
    reference_url   = data[:reference_url]
    description     = data[:description]

    # journal entry lines
    lines = []

    # buyer line
    buyer_ar = account_receivable buyer_id, role: :buyer
    lines.push credit_line(account: buyer_ar, amount: purchase_amount)

    # payment fees line
    payment_fees = global_account :payment_fees
    lines.push debit_line(account: payment_fees, amount: payment_fee)

    # escrow line
    escrow = global_account :escrow
    lines.push debit_line(account: escrow, amount: purchase_amount - payment_fee)

    # post the lines
    return post_transaction :card_charge_success, transaction_id, lines, {
      description: description,
      reference_url: reference_url
    }
  end

  def payout(data)
    data = data.symbolize_keys

    # transaction attributes    
    transaction_id = data[:transaction_id]
    account_id     = data[:account_id]
    account_role   = data[:account_role]
    payout_amount  = BigDecimal.new data[:payout_amount]
    reference_url  = data[:reference_url]
    description    = data[:description]

    # journal entry lines
    lines = []

    # buyer line
    entity_ap = account_payable account_id, role: account_role
    lines.push debit_line(account: entity_ap, amount: payout_amount)

    # escrow line
    escrow = global_account :escrow
    lines.push credit_line(account: escrow, amount: payout_amount)

    # post lines
    return post_transaction "payout_#{account_role}", transaction_id, lines, {
      description: description,
      reference_url: reference_url
    }
  end
end
