class SubledgerService

  def initialize()
  end

  def subledger
    @subledger ||= Subledger.new(cached_get_setup.slice("key_id", "identity_id", "secret", "org_id", "book_id").symbolize_keys)
  end

  # create the journal entries related to a successfully processed payment:
  # - debit purchase amount from cash_at_gateway account
  # - debit merchant amount from merchant account payable
  # - credit gateway fees on gateway fees account
  # - credit atpay fees on atpay revenue account
  def payment_successfully_processed(transaction_id, merchant_id, purchase_amount, merchant_amount, gateway_fees, atpay_fees, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: get_cash_at_gateway_account,
          value: subledger.debit(purchase_amount)
        },
        {
          account: to_subledger_account_id(merchant_id, :accounts_payable, subledger.credit),
          value: subledger.credit(merchant_amount)
        },
        {
          account: get_gateway_fees_account,
          value: subledger.credit(gateway_fees)
        },
        {
          account: get_atpay_revenue_account,
          value: subledger.credit(atpay_fees)
        }
      ]
    )

    # map transaction id
    if transaction_id.present?
      Mapping.map_entity("transaction::payment_successfully_processed", transaction_id, result.id)
    end

    return result
  end

  # create the journal entries related to a merchant payout:
  # - credit payout value on cash at bank account
  # - debit payout value from merchant account
  def payout_to_merchant(transaction_id, merchant_id, payout_amount, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: get_cash_at_bank_account,
          value:   subledger.credit(payout_amount)
        },
        {
          account: to_subledger_account_id(merchant_id, :accounts_payable, subledger.credit),
          value:  subledger.debit(payout_amount)
        }
      ]
    )

    # map transaction id
    if transaction_id.present?
      Mapping.map_entity("transaction::payout_to_merchant", transaction_id, result.id)
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
      "cash_at_gateway_account_id" => AppConfig.get_value("SUBLEDGER_CASH_AT_GATEWAY_ACCOUNT_ID"),
      "gateway_fees_account_id"    => AppConfig.get_value("SUBLEDGER_GATEWAY_FEES_ACCOUNT_ID"),
      "atpay_revenue_account_id"   => AppConfig.get_value("SUBLEDGER_ATPAY_REVENUE_ACCOUNT_ID"),
      "cash_at_bank_account_id"    => AppConfig.get_value("SUBLEDGER_CASH_AT_BANK_ACCOUNT_ID"),
      "ap_category_id"             => AppConfig.get_value("SUBLEDGER_AP_CATEGORY_ID")
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
    cash_at_gateway_account = create_global_account(
      "Cash At Gateway",
      "http://www.atpay.com/cash_at_gateway",
       @subledger.debit
    )

    gateway_fees_account = create_global_account(
      "Gateway Fees",
      "http://www.atpay.com/gateway_fees",
      @subledger.debit
    )

    atpay_revenue_account = create_global_account(
      "AtPay Revenue",
      "http://www.atpay.com/atpay_revenue",
      @subledger.credit
    )

    cash_at_bank_account = create_global_account(
      "Cash at Bank",
      "http://www.atpay.com/cash_at_bank",
      @subledger.credit
    )

    # create report
    ap_category_id = create_report(
      cash_at_gateway_account,
      gateway_fees_account,
      atpay_revenue_account,
      cash_at_bank_account
    )

    # evict own cache
    evict_cache

    result = {
      "SUBLEDGER_KEY_ID"                     => key.id,
      "SUBLEDGER_IDENTITY_ID"                => identity.id,
      "SUBLEDGER_SECRET"                     => key.secret,
      "SUBLEDGER_ORG_ID"                     => org.id,
      "SUBLEDGER_BOOK_ID"                    => book.id,
      "SUBLEDGER_CASH_AT_GATEWAY_ACCOUNT_ID" => cash_at_gateway_account.id,
      "SUBLEDGER_GATEWAY_FEES_ACCOUNT_ID"    => gateway_fees_account.id,
      "SUBLEDGER_ATPAY_REVENUE_ACCOUNT_ID"   => atpay_revenue_account.id,
      "SUBLEDGER_CASH_AT_BANK_ACCOUNT_ID"    => cash_at_bank_account.id,
      "SUBLEDGER_AP_CATEGORY_ID"             => ap_category_id
    }

    block_given? ? yield(result) : result
  end

private
  def get_cash_at_gateway_account
    @cash_at_gateway_account ||= subledger.accounts.new_or_create(id: cached_get_setup["cash_at_gateway_account_id"])
  end

  def get_gateway_fees_account
    @gatewat_fees_account ||= subledger.accounts.new_or_create(id: cached_get_setup['gateway_fees_account_id'])
  end

  def get_atpay_revenue_account
    @atpay_revenue_account ||= subledger.accounts.new_or_create(id: cached_get_setup['atpay_revenue_account_id'])
  end

  def get_cash_at_bank_account
    @cash_at_bank_account ||= subledger.accounts.new_or_create(id: cached_get_setup['cash_at_bank_account_id'])
  end

  def get_ap_category
    @ap_category ||= subledger.category.read(id: cached_get_setup['ap_category_id'])
  end

  def to_subledger_account_id(third_party_account_id, account_type, normal_balance)
    # calculate the third party account key
    third_party_account_key = "#{third_party_account_id}_#{account_type.to_s}"
    
    # get the subledger account id
    account_id = Mapping.entity_map_value("account", third_party_account_key)

    # instantiate/create the account
    return subledger.accounts.new_or_create(
      id: account_id,
      description: CGI::escape(third_party_account_key),
      normal_balance: normal_balance) do |account|

        puts "aqui"

      # update cache and file if this is a new account
      unless Mapping.entity_map_exists?("account", third_party_account_key)
        Mapping.map_entity("account", third_party_account_key, account.id)

        # add to report
        case account_type
        when :accounts_payable
          get_ap_category.attach account: account
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

  def create_report(cash_at_gateway_account, gateway_fees_account, atpay_revenue_account, cash_at_bank_account)
    Rails.logger.info "  - Creating Report..."

    # create categories
    assets_category = @subledger.categories.create description: 'Assets',
                                                   normal_balance: @subledger.debit,
                                                   version: 1

    cash_category = @subledger.categories.create description: 'Cash',
                                                 normal_balance: @subledger.debit,
                                                 version: 1

    liabilities_category = @subledger.categories.create description: 'Liabilities',
                                                        normal_balance: @subledger.credit,
                                                        version: 1

    ap_category = @subledger.categories.create description: 'Accounts Payable',
                                               normal_balance: @subledger.credit,
                                               version: 1

    revenue_category = @subledger.categories.create description: 'Revenue',
                                                    normal_balance: @subledger.credit,
                                                    version: 1

    expense_category = @subledger.categories.create description: 'Expense',
                                                    normal_balance: @subledger.debit,
                                                    version: 1

    # attach global accounts to categories
    cash_category.attach account: cash_at_gateway_account
    cash_category.attach account: cash_at_bank_account

    revenue_category.attach account: atpay_revenue_account

    expense_category.attach account: gateway_fees_account

    # create the report
    balance_sheet = @subledger.report.create description: 'Chart of Accounts'

    # attach categories to report
    balance_sheet.attach category: assets_category
    balance_sheet.attach category: liabilities_category
    balance_sheet.attach category: revenue_category
    balance_sheet.attach category: expense_category

    balance_sheet.attach category: cash_category,
                         parent:   assets_category

    balance_sheet.attach category: ap_category,
                         parent:   liabilities_category

    return ap_category.id
  end

end
