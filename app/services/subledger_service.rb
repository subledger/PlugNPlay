class SubledgerService < ApplicationService
  knows_accounting

  def user_deposit(data)
    lines = []

    return lines
  end

  def user_funds_received(data)
    user_id     = data[:user_id]
    user_funds  = BigDecimal.new data[:user_funds]
    gateway_fee = BigDecimal.new data[:gateway_fee]

    # calculate depoist amount
    deposit_amount  = user_funds + gateway_fee

    return [
      debit_line(global_account: :cash_at_bank, amount: deposit_amount),
      credit_line(accounts_payable: user_id, amount: user_funds, callback: user_subcategory),
      credit_line(global_account: :gateway_revenue, amount: gateway_fee)
    ]
  end

  def user_ripple_wallet_funded(data)
    user_id = data[:user_id]
    amount  = BigDecimal.new data[:amount]

    return [
      credit_line(global_account: :cash_at_wallet, amount: amount),
      debit_line(accounts_payable: user_id, amount: amount, callback: user_subcategory)
    ]
  end

  def bank_to_ripple_wallet(data)
    amount = BigDecimal.new data[:amount]

    return [
      debit_line(global_account: :cash_at_wallet, amount: amount),
      credit_line(global_account: :cash_at_bank, amount: amount)
    ]
  end

  def user_funds_transferred_out_of_bank(data)
    user_id         = data[:user_id]
    transfer_amount = BigDecimal.new data[:transfer_amount]
    gateway_fee     = BigDecimal.new data[:gateway_fee]

    # calculate total amount
    total_amount = transfer_amount + gateway_fee

    return [
      credit_line(global_account: :cash_at_bank, amount: transfer_amount),
      debit_line(accounts_payable: user_id, amount: total_amount, callback: user_subcategory),
      credit_line(global_account: :gateway_revenue, amount: gateway_fee)
    ]
  end

  def user_funds_transferred_off_ripple_network(data)
    user_id = data[:user_id]
    amount  = BigDecimal.new data[:amount]

    return [
      debit_line(global_account: :cash_at_wallet, amount: amount),
      credit_line(accounts_payable: user_id, amount: amount, callback: user_subcategory)
    ]
  end

  def ripple_wallet_to_bank(data)
    amount = BigDecimal.new data[:amount]

    return [
      credit_line(global_account: :cash_at_wallet, amount: amount),
      debit_line(global_account: :cash_at_bank, amount: amount)
    ]
  end

private
  # makes sure a subcategory exists for the given user
  user_subcategory = Proc.new do |account, amount, config|
    # get user id from config
    user_id = config[:accounts_payable]

    # create a subcategory for this user and attach if to report
    category(user_id, normal_balance: credit)
    attach_category_to_report user_id, :balance, parent_category_id: :accounts_payable

    # attach the user account to the category
    attach_account_to_category accounts_payable(user_id), user_id
  end  
end
