class SubledgerService < ApplicationService
  knows_accounting

  def initialize
    # makes sure a subcategory exists for the given user
    @user_subcategory = Proc.new do |account, amount, config|
      # get user id from config
      user_id = config[:account_payable_id]

      # create a subcategory for this user and attach if to report
      category user_id, normal_balance: credit
      attach_category_to_report user_id, :balance, parent_category_id: :accounts_payable

      # attach the user account to the category
      attach_account_to_category account, user_id
    end  
  end
  
  def user_balance(data)
    user_id = data[:user_id]
    at      = data[:at].present? ? data[:at].to_time : Time.now

    account(user_id, data.slice(:sufixes, :prefixes)).balance({
      at: at
    })
  end

  def user_history(data)
    user_id  = data[:user_id]
    per_page = data[:per_page]
    date     = data[:date].present? ? data[:date].to_time : nil
    page_id  = data[:page_id]
    order    = data[:order].present? ? data[:order].to_sym : :asc

    config = { limit: per_page || 25 }

    if order == :desc
      if page_id.present?
        config = config.merge( action: :preceding, id: page_id )

      else
        date = date || Time.now
        config = config.merge( action: :ending, effective_at: date )
      end

    else
      if page_id.present?
        config = config.merge( action: :following, id: page_id )

      else
        date = date || Time.new(1970)
        config = config.merge( action: :starting, effective_at: date )
      end

    end

    account(user_id, data.slice(:sufixes, :prefixes)).lines(config)
  end

  def user_funds_received(data)
    user_id        = data[:user_id]
    deposit_amount = BigDecimal.new data[:deposit_amount]
    user_funds     = BigDecimal.new data[:user_funds]
    gateway_fee    = BigDecimal.new data[:gateway_fee]

    return [
      debit_line(global_account_id: :cash_at_bank, amount: deposit_amount),
      credit_line(account_payable_id: user_id, amount: user_funds, callback: @user_subcategory),
      credit_line(global_account_id: :gateway_revenue, amount: gateway_fee)
    ]
  end

  def user_ripple_wallet_funded(data)
    user_id = data[:user_id]
    amount  = BigDecimal.new data[:amount]

    return [
      credit_line(global_account_id: :cash_at_wallet, amount: amount),
      debit_line(account_payable_id: user_id, amount: amount, callback: @user_subcategory)
    ]
  end

  def bank_to_ripple_wallet(data)
    amount = BigDecimal.new data[:amount]

    return [
      debit_line(global_account_id: :cash_at_wallet, amount: amount),
      credit_line(global_account_id: :cash_at_bank, amount: amount)
    ]
  end

  def user_funds_transferred_out_of_bank(data)
    user_id         = data[:user_id]
    total_amount    = BigDecimal.new data[:total_amount]
    transfer_amount = BigDecimal.new data[:transfer_amount]
    gateway_fee     = BigDecimal.new data[:gateway_fee]

    return [
      credit_line(global_account_id: :cash_at_bank, amount: transfer_amount),
      debit_line(account_payable_id: user_id, amount: total_amount, callback: @user_subcategory),
      credit_line(global_account_id: :gateway_revenue, amount: gateway_fee)
    ]
  end

  def user_funds_transferred_off_ripple_network(data)
    user_id = data[:user_id]
    amount  = BigDecimal.new data[:amount]

    return [
      debit_line(global_account_id: :cash_at_wallet, amount: amount),
      credit_line(account_payable_id: user_id, amount: amount, callback: @user_subcategory)
    ]
  end

  def ripple_wallet_to_bank(data)
    amount = BigDecimal.new data[:amount]

    return [
      credit_line(global_account_id: :cash_at_wallet, amount: amount),
      debit_line(global_account_id: :cash_at_bank, amount: amount)
    ]
  end

end
