module PnpDsl
  def subledger
    @subledger ||= Subledger.new(
      key_id:      AppConfig.find_by key: "key_id",
      identity_id: AppConfig.find_by key: "identity_id",
      secret:      AppConfig.find_by key: "secret",
      org_id:      AppConfig.find_by key: "org_id",
      book_id:     AppConfig.find_by key: "book_id"
    )
  end

  def credit(amount = nil)
    amount.present? ? subledger.credit(amount) : subledger.credit
  end

  def debit(amount = nil)
    amount.present? ? subledger.debit(amount) : subledger.debit
  end

  def account(id, config = {})
    config = config.symbolize_keys

    # required parameters
    id = id.to_sym
    role = config[:role]
    type = config[:type]
    normal_balance = config[:normal_balance]

    # optional parameters
    category = config[:category]

    # get subledger id calculated from config
    subledger_id, key = to_subledger_id :account, id, sufixes: [role, type]
   
    # instantiate/create the account
    subledger.accounts.new_or_create(
      id: subledger_id,
      description: CGI::escape(key),
      normal_balance: normal_balance) do |account|

      unless Mapping.entity_map_exists?(:account, key)
        # update cache and file if this is a new account
        Mapping.map_entity(:account, key, account.id)

        # attach to a report category category, if one was provided
        if category.present?
          attach_account_to_category account, category
        end

        return account
      end
    end
  end

  def global_account(id, config = {})
    normal_config = { role: id.to_sym, type: id.to_sym }
    account id, normal_config.merge(config)
  end

  def account_receivable(id, config = {})
    normal_config = { type: :accounts_receivable, normal_balance: credit }
    account id: id, normal_config.merge(config)
  end

  def account_payable(id, role, category = nil)
    normal_config = { type: :accounts_payable, normal_balance: debit }
    account id: id, normal_config.merge(config)
  end

  # config = :id, :normal_balance
  def category(config = {})
    config = config.symbolize_keys

    # get subledger id calculated from config
    subledger_id, key = to_subledger_id(:category, config[:id])

    if subledger_id.present?
      subledger.categories.read(id: subledger_id)
    else
      # create the category
      the_category = subledger.categories.create description: "#{config[:id].humanize}",
                                                 normal_balance: config[:normal_balance],
                                                 version: 1
      # save new mapping
      Mapping.map_entity("category", key, the_category.id)

      return the_category
    end
  end

  def report(config = {})
    config = config.symbolize_keys
    id = config[:id]

    # get calculated Subledger id
    subledger_id, key = to_subledger_id :report, id

    if subledger_id.present?
      # return the report if already mapped
      subledger.reports.read id: subledger_id

    else
      # create the report
      the_report = subledger.reports.create description: id.humanize,
                                            reference: config[:reference_url]
      # save new mapping
      Mapping.map_entity(:report, key, the_report.id)

      return the_report
    end
  end

 def line(account, amount)
    return account: account, value: amount
  end

  def credit_line(account, amount_value)
    return line account, credit(amount_value)
  end

  def debit_line(account, amount_value)
    return line account, debit(amount_value)
  end

  def post_lines(transaction, transaction_id, lines, config = {})
    result = subledger.journal_entry.create_and_post(
      effective_at: config[:effetice_at] || Time.now,
      description:  config[:description],
      reference:    config[:reference_url],
      lines:        lines
    )

    if transaction_id.present?
      key = "transaction::#{transaction}"
      Mapping.map_entity key, transaction_id, result.id
    end

    return result
  end

private
  def to_subledger_id(what, id, sufixes= [])
    # replace chars on account id for readability
    id = id.to_s.tr("[@,.]", "_")

    # calculate the third party account key
    key = ([what, id] + sufixes).join "_"

    # get the subledger account id
    subledger_id = Mapping.entity_map_value(what, key)

    return subledger_id, key
  end
end
