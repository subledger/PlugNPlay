class SubledgerService < ApplicationService
  knows_accounting

  def initialize
    # makes sure a subcategory exists for a given account payable role
    # and that it is attached to the report
    @ap_role_subcategory = Proc.new do |account, amount, config|
      # get intermediate role from config
      role = config[:role]

      # create a subcategory for this role
      category role, normal_balance: credit

      # and attach it to report
      attach_category_to_report role, :balance, parent_category_id: :accounts_payable

      # attach the user account to the category
      attach_account_to_category account, role
    end
  end


  ### User with an account (Wallet Style)

  def user_adds_credit_using_credit_card(data)
    user_id            = data[:user_id]
    payment_amount     = BigDecimal.new data[:payment_amount]
    intermediate_id    = data[:intermediate_id]
    intermediate_role  = data[:intermediate_role]
    intermediation_fee = BigDecimal.new data[:intermediation_fee]

    balance = payment_amount - intermediation_fee

    return [
      debit_line(
        account_receivable_id: user_id,
        amount: payment_amount,
        category_id: :accounts_receivable
      ),
      credit_line(
        account: user_unused_balance_processing_account(user_id),
        amount: balance
      ),
      credit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    ]
  end

  def user_credit_added_successfully(data)
    user_id             = data[:user_id]
    payment_amount      = BigDecimal.new data[:payment_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    intermediation_fee  = BigDecimal.new data[:intermediation_fee]

    balance = payment_amount - intermediation_fee

    return [
      credit_line(
        account_receivable_id: user_id,
        amount: payment_amount,
        category_id: :accounts_receivable
      ),
      debit_line(
        account: user_unused_balance_processing_account(user_id),
        amount: balance
      ),
      credit_line(
        account: user_unused_balance_account(user_id),
        amount: balance
      ),
      debit_line(
        global_account_id: :escrow,
        amount: balance
      ),
      debit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    ]
  end

  def purchase_with_balance(data)
    user_id         = data[:user_id]
    purchase_amount = BigDecimal.new data[:purchase_amount]
    revenue_amount  = BigDecimal.new data[:revenue_amount]
    payables        = data[:payables]

    lines = []

    # user unused balance line
    lines << debit_line(
      account: user_unused_balance_account(user_id),
      amount: purchase_amount
    )

    # lines for each payable
    payables.each do |payable|
      payable = payable.symbolize_keys

      # line attributes
      account_id = payable[:id]
      role = payable[:role].to_sym
      amount = BigDecimal.new payable[:amount]

      lines << credit_line(
        account_payable_id: account_id,
        role: role,
        amount: amount,
        callback: @ap_role_subcategory
      )
    end

    # revenue line
    lines << credit_line(
      global_account_id: :revenue,
      amount: revenue_amount
    )

    return lines
  end

  def refund_purchase_to_user_account(data)
    user_id         = data[:user_id]
    refund_amount   = BigDecimal.new data[:refund_amount]
    revenue_amount  = BigDecimal.new data[:revenue_amount]
    payables        = data[:payables]

    lines = []

    # user unused balance line
    lines << credit_line(
      account: user_unused_balance_account(user_id),
      amount: refund_amount
    )

    # lines for each payable
    payables.each do |payable|
      payable = payable.symbolize_keys

      # line attributes
      account_id = payable[:id]
      role = payable[:role].to_sym
      amount = BigDecimal.new payable[:amount]

      lines << debit_line(
        account_payable_id: account_id,
        role: role,
        amount: amount,
        callback: @ap_role_subcategory
      )
    end

    # revenue line
    lines << debit_line(
      global_account_id: :revenue,
      amount: revenue_amount
    )

    return lines
  end


  ### Drop-in user (not signed up)

  def purchase_with_credit_card(data)
    user_id             = data[:user_id]
    purchase_amount     = BigDecimal.new data[:purchase_amount]
    revenue_amount      = BigDecimal.new data[:revenue_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    intermediation_fee  = BigDecimal.new data[:intermediation_fee]
    payables            = data[:payables]

    lines = []

    # user account receivable line
    lines << debit_line(
      account_receivable_id: user_id,
      amount: purchase_amount,
      category_id: :accounts_receivable
    )

    # intermediate line
    lines << credit_line(
      account_payable_id: intermediate_id,
      role: intermediate_role,
      amount: intermediation_fee,
      callback: @ap_role_subcategory
    )

    # lines for each payable
    payables.each do |payable|
      payable = payable.symbolize_keys

      # line attributes
      account_id = payable[:id]
      role = payable[:role].to_sym
      amount = BigDecimal.new payable[:amount]

      lines << credit_line(
        account_payable_id: account_id,
        role: role,
        amount: amount,
        callback: @ap_role_subcategory
      )
    end

    # revenue line
    lines << credit_line(
      global_account_id: :revenue,
      amount: revenue_amount
    )

    return lines
  end

  def credit_card_charge_success(data)
    user_id             = data[:user_id]
    purchase_amount      = BigDecimal.new data[:purchase_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    intermediation_fee  = BigDecimal.new data[:intermediation_fee]

    balance = purchase_amount - intermediation_fee

    return [
      credit_line(
        account_receivable_id: user_id,
        amount: purchase_amount,
        category_id: :accounts_receivable
      ),
      debit_line(
        global_account_id: :escrow,
        amount: balance
      ),
      debit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    ]
  end

  def refund_to_credit_card(data)
    user_id             = data[:user_id]
    refund_amount       = BigDecimal.new data[:refund_amount]
    revenue_amount      = BigDecimal.new data[:revenue_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    intermediation_fee  = BigDecimal.new data[:intermediation_fee]
    payables            = data[:payables]
    
    lines = []

    # escrow account lines
    lines << credit_line(
      global_account_id: :escrow,
      amount: refund_amount,
    )

    lines << debit_line(
      global_account_id: :escrow,
      amount: intermediation_fee,
    )

    # lines for each payable
    payables.each do |payable|
      payable = payable.symbolize_keys

      # line attributes
      account_id = payable[:id]
      role = payable[:role].to_sym
      amount = BigDecimal.new payable[:amount]

      lines << debit_line(
        account_payable_id: account_id,
        role: role,
        amount: amount,
        callback: @ap_role_subcategory
      )
    end

    # revenue line
    lines << debit_line(
      global_account_id: :revenue,
      amount: revenue_amount
    )

    return lines
  end


  ### Independent from payment method

  def payout(data)
    account_id     = data[:account_id]
    account_role   = data[:account_role]
    payout_amount  = BigDecimal.new data[:payout_amount]

    return [
      debit_line(
        account_payable_id: account_id,
        role: account_role,
        amount: payout_amount,
        callback: @ap_role_subcategory
      ),
      credit_line(
        global_account_id: :escrow,
        amount: payout_amount
      )
    ]
  end

private
  def user_unused_balance_account(user_id)
    account user_id, {
      normal_balance: credit,
      sufixes: [:unused_balance],
      category_id: :unused_balance 
    }
  end

  def user_unused_balance_processing_account(user_id)
    account user_id, {
      normal_balance: credit,
      sufixes: [:unused_balance_processing],
      category_id: :unused_balance_processing
    }
  end
end
