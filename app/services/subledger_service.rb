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
    buyer_ar = account_receivable buyer_id, role: :buyer, category_id: :accounts_receivable
    lines.push debit_line(account: buyer_ar, amount: purchase_amount)

    # lines for each other payable
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
      entity_account_payable = account_payable account_id, role: role, category_id: role

      lines.push credit_line(account: entity_account_payable, amount: amount)
    end

    # revenue line
    revenue = global_account :revenue
    lines.push credit_line(account: revenue, amount: revenue_amount)

    # post the lines
    return post_transaction :goods_sold, transaction_id, lines, {
      description: description,
      reference_url: reference_url
    }
  end

  def card_charge_success(data)
    data = data .symbolize_keys
  
    # transaction data  
    transaction_id      = data[:transaction_id]
    buyer_id            = data[:buyer_id]
    purchase_amount     = BigDecimal.new data[:purchase_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    intermediation_fee  = BigDecimal.new data[:intermediation_fee]
    reference_url       = data[:reference_url]
    description         = data[:description]

    # journal entry lines
    lines = []

    # buyer line
    buyer_ar = account_receivable buyer_id, role: :buyer, category_id: :accounts_receivable
    lines.push credit_line(account: buyer_ar, amount: purchase_amount)

    # intermediate fees line
    intermediate_ap = account_payable intermediate_id, role: intermediate_role
    lines.push debit_line(account: intermediate_ap, amount: intermediation_fee)

    # escrow line
    escrow = global_account :escrow
    lines.push debit_line(account: escrow, amount: purchase_amount - intermediation_fee)

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
