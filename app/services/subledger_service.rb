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

    # makes sure an accounts payable subcategory for the users
    @ap_users_subcategory = Proc.new do |account, amount, config|
      # create a subcategory for this role
      category :users, normal_balance: credit

      # and attach it to report
      attach_category_to_report :users, :balance, parent_category_id: :accounts_payable

      # attach the user account to the category
      attach_account_to_category account, :users
    end
  end


  ### User with an account (Wallet Style)

  def user_adds_credit_using_credit_card(data)
    user_id            = data[:user_id]
    payment_amount     = BigDecimal.new data[:payment_amount]
    intermediate_id    = data[:intermediate_id]
    intermediate_role  = data[:intermediate_role]

    balance = payment_amount

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
      balance -= intermediation_fee
    end

    lines = []

    lines << debit_line(
      account_receivable_id: user_id,
      amount: payment_amount,
      category_id: :accounts_receivable
    )

    lines << credit_line(
      account: user_unused_balance_processing_account(user_id),
      amount: balance
    )

    if intermediation_fee.present?
      lines << credit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

    return lines
  end

  def user_credit_added_successfully(data)
    user_id             = data[:user_id]
    payment_amount      = BigDecimal.new data[:payment_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]

    balance = payment_amount

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
      balance -= intermediation_fee
    end

    lines = []

    lines << credit_line(
      account_receivable_id: user_id,
      amount: payment_amount,
      category_id: :accounts_receivable
    )

    lines << debit_line(
      account: user_unused_balance_processing_account(user_id),
      amount: balance
    )

    lines << credit_line(
      account: user_unused_balance_account(user_id),
      amount: balance
    )

    lines << debit_line(
      global_account_id: :escrow,
      amount: balance
    )

    if intermediation_fee.present?
      lines << debit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

    return lines    
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

  def transfer_to_external_account(data)
    user_id             = data[:user_id]
    transfer_amount     = BigDecimal.new data[:transfer_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]

    total_amount = transfer_amount

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
      total_amount += intermediation_fee
    end

    lines = []

    lines << debit_line(
      account: user_unused_balance_account(user_id),
      amount: total_amount
    )

    lines << credit_line(
      account_payable_id: user_id,
      amount: transfer_amount,
      callback: @ap_users_subcategory
    )

    if intermediation_fee.present?
      lines << credit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

    return lines
  end

  def transfer_to_external_account_successfull(data)
    user_id             = data[:user_id]
    transfer_amount     = BigDecimal.new data[:transfer_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]

    total_amount = transfer_amount

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
      total_amount += intermediation_fee
    end

    lines = []

    lines << credit_line(
      global_account_id: :escrow,
      amount: total_amount
    )

    lines << debit_line(
      account_payable_id: user_id,
      amount: transfer_amount,
      callback: @ap_users_subcategory
    )

    if intermediation_fee.present?
      lines <<  debit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

    return lines
  end

  def transfer_to_wallet(data)
    user_id             = data[:user_id]
    user_role           = data[:user_role]
    transfer_amount     = BigDecimal.new data[:transfer_amount]

    return [
      debit_line(
        account_payable_id: user_id,
        role: user_role,
        amount: transfer_amount, 
        callback: @ap_users_subcategory
      ),
      credit_line(
        account: user_unused_balance_account(user_id),
        amount: transfer_amount
      )
    ]
  end

  ### Drop-in user (not signed up)

  def purchase_with_credit_card(data)
    user_id             = data[:user_id]
    purchase_amount     = BigDecimal.new data[:purchase_amount]
    revenue_amount      = BigDecimal.new data[:revenue_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    payables            = data[:payables]

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
    end

    lines = []

    # user account receivable line
    lines << debit_line(
      account_receivable_id: user_id,
      amount: purchase_amount,
      category_id: :accounts_receivable
    )

    # intermediate line
    if intermediation_fee.present?
      lines << credit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

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

    balance = purchase_amount

    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
      balance -= intermediation_fee
    end

    lines = []

    lines << credit_line(
      account_receivable_id: user_id,
      amount: purchase_amount,
      category_id: :accounts_receivable
    )

    lines << debit_line(
      global_account_id: :escrow,
      amount: balance
    )

    if intermediation_fee.present?
      lines << debit_line(
        account_payable_id: intermediate_id,
        role: intermediate_role,
        amount: intermediation_fee,
        callback: @ap_role_subcategory
      )
    end

    return lines
  end

  def refund_to_credit_card(data)
    user_id             = data[:user_id]
    refund_amount       = BigDecimal.new data[:refund_amount]
    revenue_amount      = BigDecimal.new data[:revenue_amount]
    intermediate_id     = data[:intermediate_id]
    intermediate_role   = data[:intermediate_role]
    payables            = data[:payables]
    
    if data[:intermediation_fee].present?
      intermediation_fee  = BigDecimal.new data[:intermediation_fee]
    end

    lines = []

    # escrow account lines
    lines << credit_line(
      global_account_id: :escrow,
      amount: refund_amount,
    )

    if intermediation_fee.present?
      lines << debit_line(
        global_account_id: :escrow,
        amount: intermediation_fee,
      )
    end

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
