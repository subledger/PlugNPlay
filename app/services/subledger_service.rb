class SubledgerService

  def initialize()
  end

  def subledger
    @subledger ||= Subledger.new(cached_get_setup.slice("key_id", "identity_id", "secret", "org_id", "book_id").symbolize_keys)
  end

  def goods_sold(transaction_id, buyer_id, purchase_amount, revenue_amount, payables = [], reference_url, description)
    lines = [
      {
        account: to_subledger_account_id(buyer_id, :buyer, :accounts_receivable, subledger.debit),
        value: subledger.debit(purchase_amount)
      },
      {
        account: get_revenue_account,
        value: subledger.credit(revenue_amount)
      }
    ]

    payables.each do |payable|
      payable = payable.symbolize_keys

      lines.push(
        account: to_subledger_account_id(payable[:id], payable[:role], :accounts_payable,  subledger.credit),
        value: subledger.credit(BigDecimal.new(payable[:amount]))
      )
    end

    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        lines
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::goods_sold", transaction_id, result.id)
    end

    return result
  end

  def card_charge_success(transaction_id, buyer_id, purchase_amount, payment_fee, reference_url, description)
    remainder = purchase_amount - payment_fee

    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: to_subledger_account_id(buyer_id, :buyer, :accounts_receivable, subledger.debit),
          value: subledger.credit(purchase_amount)
        },
        {
          account: get_payment_fees_account,
          value: subledger.debit(payment_fee)
        },
        {
          account: get_escrow_account,
          value: subledger.debit(remainder)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::card_charge_success", transaction_id, result.id)
    end

    return result
  end

  def payout(transaction_id, account_id, account_role, payout_amount, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: to_subledger_account_id(account_id, account_role, :accounts_payable, subledger.credit),
          value:  subledger.debit(payout_amount)
        },
        {
          account: get_escrow_account,
          value:   subledger.credit(payout_amount)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::payout_#{account_role}", transaction_id, result.id)
    end

    return result
  end

  def cached_get_setup
    Rails.cache.fetch(["subledger", "setup"]) { get_setup }
  end

  def get_setup
    return {
      "key_id"                     => AppConfig.get_value("SUBLEDGER_KEY_ID"),
      "identity_id"                => AppConfig.get_value("SUBLEDGER_IDENTITY_ID"),
      "secret"                     => AppConfig.get_value("SUBLEDGER_SECRET"),
      "org_id"                     => AppConfig.get_value("SUBLEDGER_ORG_ID"),
      "book_id"                    => AppConfig.get_value("SUBLEDGER_BOOK_ID"),
      "escrow_account_id"          => AppConfig.get_value("SUBLEDGER_ESCROW_ACCOUNT_ID"),
      "revenue_account_id"         => AppConfig.get_value("SUBLEDGER_REVENUE_ACCOUNT_ID"),
      "payment_fees_account_id"    => AppConfig.get_value("SUBLEDGER_PAYMENT_FEES_ACCOUNT_ID"),
      "report_id"                  => AppConfig.get_value("SUBLEDGER_REPORT_ID"),
      "cash_category_id"           => AppConfig.get_value("SUBLEDGER_CASH_CATEGORY_ID"),
      "ap_category_id"             => AppConfig.get_value("SUBLEDGER_AP_CATEGORY_ID"),
      "ar_category_id"             => AppConfig.get_value("SUBLEDGER_AR_CATEGORY_ID")
    }
  end

  def evict_cache
    Rails.cache.delete(["subledger", "setup"])
    @subledger = nil
  end

  def setup_ready?
    AppConfig.exists?(key: "SUBLEDGER_KEY_ID")
  end

  def initial_setup(config)
    email         = config[:email]
    identity_desc = config[:identity_desc]
    org_desc      = config[:org_desc]
    book_desc     = config[:book_desc]

    # create blank subledger instance
    @subledger = Subledger.new

    # create identity
    identity, key = create_identity(email, identity_desc)

    # recreate subledger instance using key and secret
    @subledger = Subledger.new key_id: key.id,
                               secret: key.secret

    # create org
    org = create_org(org_desc)

    # create book
    book = create_book(org, book_desc)

    # recreate subledger instance
    @subledger = Subledger.new key_id:      key.id,
                               identity_id: identity.id,
                               secret:      key.secret,
                               org_id:      org.id,
                               book_id:     book.id

    # create global accounts
    escrow_account = create_global_account(
      "Granular Escrow",
      "http://getgranular.com/subledger/granular_escrow",
      @subledger.debit
    )

    revenue_account = create_global_account(
      "Granular Revenue",
      "http://getgranular.com/subledger/granular_revenue",
      @subledger.credit
    )

    payment_fees_account = create_global_account(
      "Payment Fees",
      "http://getgranular.com/subledger/payment_fees",
      @subledger.debit
    )

    # create report
    report, cash_category, ap_category, ar_category = create_report(
      escrow_account,
      revenue_account,
      payment_fees_account
    )

    # evict own cache
    evict_cache

    result = {
      "SUBLEDGER_KEY_ID"                     => key.id,
      "SUBLEDGER_IDENTITY_ID"                => identity.id,
      "SUBLEDGER_SECRET"                     => key.secret,
      "SUBLEDGER_ORG_ID"                     => org.id,
      "SUBLEDGER_BOOK_ID"                    => book.id,
      "SUBLEDGER_ESCROW_ACCOUNT_ID"          => escrow_account.id,
      "SUBLEDGER_REVENUE_ACCOUNT_ID"         => revenue_account.id,
      "SUBLEDGER_PAYMENT_FEES_ACCOUNT_ID"    => payment_fees_account.id,
      "SUBLEDGER_REPORT_ID"                  => report.id,
      "SUBLEDGER_CASH_CATEGORY_ID"           => cash_category.id,
      "SUBLEDGER_AP_CATEGORY_ID"             => ap_category.id,
      "SUBLEDGER_AR_CATEGORY_ID"             => ar_category.id
    }

    block_given? ? yield(result) : result
  end

private
  def get_escrow_account
    @escrow_account ||= subledger.accounts.new_or_create(id: cached_get_setup["escrow_account_id"])
  end

  def get_revenue_account
    @revenue_account ||= subledger.accounts.new_or_create(id: cached_get_setup['revenue_account_id'])
  end

  def get_payment_fees_account
    @payment_fees_account ||= subledger.accounts.new_or_create(id: cached_get_setup['payment_fees_account_id'])
  end

  def get_report
    @report ||= subledger.report.read(id: cached_get_setup['report_id'])
  end

  def get_cash_category
    @cash_category ||= subledger.category.read(id: cached_get_setup['cash_category_id'])
  end

  def get_ap_category
    @ap_category ||= subledger.category.read(id: cached_get_setup['ap_category_id'])
  end

  def get_ap_subcategory(category_app_id)
    category_id = Mapping.entity_map_value("category", category_app_id)

    category = nil
    if category_id.present?
      category = subledger.categories.read(id: category_id)

    else
      # create the category
      category = subledger.categories.create description: "#{category_app_id.humanize} Accounts Payable",
                                             normal_balance: subledger.credit,
                                             version: 1

      # attach it to the report
      get_report.attach category: category,
                        parent: get_ap_category

      # save new mapping
      Mapping.map_entity("category", category_app_id, category.id)
    end

    return category
  end

  def get_ar_category
    @ar_category ||= subledger.category.read(id: cached_get_setup['ar_category_id'])
  end

  def to_subledger_account_id(third_party_account_id, account_role, account_type, normal_balance)
    # replace chars on account id for readability
    third_party_account_id = third_party_account_id.tr("[@,.]", "_")

    # calculate the third party account key
    third_party_account_key = "#{third_party_account_id}_#{account_role}_#{account_type.to_s}"
    
    # get the subledger account id
    account_id = Mapping.entity_map_value("account", third_party_account_key)

    # instantiate/create the account
    return subledger.accounts.new_or_create(
      id: account_id,
      description: CGI::escape(third_party_account_key),
      normal_balance: normal_balance) do |account|

      # update cache and file if this is a new account
      unless Mapping.entity_map_exists?("account", third_party_account_key)
        Mapping.map_entity("account", third_party_account_key, account.id)

        # add to report
        case account_type
          when :accounts_receivable then get_ar_category.attach account: account
          when :accounts_payable    then get_ap_subcategory(account_role).attach account: account
        end
      end
    end
  end

  def create_identity(email, description)
    Rails.logger.info "  - Creating Identity..."
    @subledger.identities.create email:       email,
                                 description: description
  end

  def create_org(description)
    Rails.logger.info "  - Creating Org..."
    @subledger.orgs.create description: description
  end

  def create_book(org, description)
    Rails.logger.info "  - Creating Book..."
    @subledger.books.create org:         org,
                           description: description
  end

  def create_global_account(description, reference, normal_balance)
    Rails.logger.info "  - Creating Global Account..."
    @subledger.account.create description:    description,
                              reference:      reference,
                              normal_balance: normal_balance
  end 

  def create_report(escrow_account, revenue_account, payment_fees_account)
    Rails.logger.info "  - Creating Report..."

    # create categories
    assets_category = @subledger.categories.create description: 'Assets',
                                                   normal_balance: @subledger.debit,
                                                   version: 1

    cash_category = @subledger.categories.create description: 'Cash',
                                                 normal_balance: @subledger.debit,
                                                 version: 1

    revenue_category = @subledger.categories.create description: 'Revenue',
                                                    normal_balance: @subledger.credit,
                                                    version: 1

    expense_category = @subledger.categories.create description: 'Expense',
                                                    normal_balance: @subledger.debit,
                                                    version: 1

    liabilities_category = @subledger.categories.create description: 'Liabilities',
                                                        normal_balance: @subledger.credit,
                                                        version: 1

    ap_category = @subledger.categories.create description: 'Accounts Payable',
                                               normal_balance: @subledger.credit,
                                               version: 1

    ar_category = @subledger.categories.create description: 'Accounts Receivable',
                                               normal_balance: @subledger.debit,
                                               version: 1

    # attach global accounts to categories
    cash_category.attach    account: escrow_account
    revenue_category.attach account: revenue_account
    expense_category.attach account: payment_fees_account

    # create the report
    balance_sheet = @subledger.report.create description: 'Chart of Accounts'

    # attach categories to report
    balance_sheet.attach category: assets_category
    balance_sheet.attach category: revenue_category
    balance_sheet.attach category: expense_category
    balance_sheet.attach category: liabilities_category

    balance_sheet.attach category: cash_category,
                         parent:   assets_category

    balance_sheet.attach category: ar_category,
                         parent:   assets_category

    balance_sheet.attach category: ap_category,
                         parent:   liabilities_category

    return [balance_sheet, cash_category, ap_category, ar_category]
  end

end
