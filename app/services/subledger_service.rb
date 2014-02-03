class SubledgerService

  def initialize()
  end

  def subledger
    @subledger ||= Subledger.new(cached_get_setup.slice("key_id", "identity_id", "secret", "org_id", "book_id").symbolize_keys)
  end

  def charge_buyer(transaction_id, purchase_amount, payment_fee, referrer_id, referrer_fee, publisher_id, publisher_fee, distributor_id, distributor_fee, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: get_granular_escrow_account,
          value: subledger.debit(purchase_amount)
        },
        {
          account: get_payment_fees_account,
          value: subledger.debit(payment_fee)
        },
        {
          account: to_subledger_account_id(referrer_id, :referrer_accounts_payable, subledger.credit),
          value: subledger.credit(referrer_fee)
        },
        {
          account: to_subledger_account_id(publisher_id, :publisher_accounts_payable, subledger.credit),
          value: subledger.credit(publisher_fee)
        },
        {
          account: to_subledger_account_id(distributor_id, :distributor_accounts_payable, subledger.credit),
          value: subledger.credit(distributor_fee)
        },
        {
          account: get_granular_revenue_account,
          value: subledger.credit(publisher_fee)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::charge_buyer", transaction_id, result.id)
    end

    return result
  end

  def payout_referrer(transaction_id, referrer_id, payout_amount, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: to_subledger_account_id(referrer_id, :referrer_accounts_payable, subledger.credit),
          value:  subledger.debit(payout_amount)
        },
        {
          account: get_granular_escrow_account,
          value:   subledger.credit(payout_amount)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::payout_referrer", transaction_id, result.id)
    end

    return result
  end

  def payout_publisher(transaction_id, publisher_id, payout_amount, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: to_subledger_account_id(publisher_id, :publisher_accounts_payable, subledger.credit),
          value:  subledger.debit(payout_amount)
        },
        {
          account: get_granular_escrow_account,
          value:   subledger.credit(payout_amount)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::payout_publisher", transaction_id, result.id)
    end

    return result
  end

  def payout_distributor(transaction_id, distributor_id, payout_amount, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: to_subledger_account_id(distributor_id, :distributor_accounts_payable, subledger.credit),
          value:  subledger.debit(payout_amount)
        },
        {
          account: get_granular_escrow_account,
          value:   subledger.credit(payout_amount)
        }
      ]
    )

    if transaction_id.present?
      Mapping.map_entity("transaction::payout_distributor", transaction_id, result.id)
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
      "granular_escrow_account_id" => AppConfig.get_value("SUBLEDGER_GRANULAR_ESCROW_ACCOUNT_ID"),
      "granular_revenue_account_id"=> AppConfig.get_value("SUBLEDGER_GRANULAR_REVENUE_ACCOUNT_ID"),
      "payment_fees_account_id"    => AppConfig.get_value("SUBLEDGER_PAYMENT_FEES__ACCOUNT_ID"),
      "referrer_ap_category_id"    => AppConfig.get_value("SUBLEDGER_REFERRER_AP_CATEGORY_ID")
      "publisher_ap_category_id"   => AppConfig.get_value("SUBLEDGER_PUBLISHER_AP_CATEGORY_ID")
      "distributor_ap_category_id" => AppConfig.get_value("SUBLEDGER_DISTRIBUTOR_AP_CATEGORY_ID")
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
    granular_escrow_account = create_global_account(
      "Granular Escrow",
      "http://getgranular.com/subledger/granular_escrow",
      @sublddger.debit
    )

    granular_revenue_account = create_global_account(
      "Granular Revenue",
      "http://getgranular.com/subledger/granular_revenue",
      @sublddger.credit
    )

    payment_fees_account = create_global_account(
      "Payment Fees",
      "http://getgranular.com/subledger/payment_fees",
      @sublddger.debit
    )

    # create report
    referrer_ap_category_id, publisher_ap_category_id, distributor_ap_category_id = create_report(
      granular_escrow_account,
      granular_revenue_account,
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
      "SUBLEDGER_GRANULAR_ESCROW_ACCOUNT_ID" => granular_escrow_account.id,
      "SUBLEDGER_GRANULAR_REVENUE_ACCOUNT_ID"=> granular_revenue_account.id,
      "SUBLEDGER_PAYMENT_FEES_ACCOUNT_ID"    => payment_fees_account.id,
      "SUBLEDGER_REFERRER_AP_CATEGORY_ID"    => referrer_ap_category_id,
      "SUBLEDGER_PUBLISHER_AP_CATEGORY_ID"   => publisher_ap_category_id,
      "SUBLEDGER_DISTRIBUTOR_AP_CATEGORY_ID" => distributor_ap_category_id,
    }

    block_given? ? yield(result) : result
  end

private
  def get_granular_escrow_account
    @granular_escrow_account ||= subledger.accounts.new_or_create(id: cached_get_setup["granular_escrow_account_id"])
  end

  def get_granular_revenue_account
    @granular_revenue_account ||= subledger.accounts.new_or_create(id: cached_get_setup['granular_revenue_account_id'])
  end

  def get_payment_fees_account
    @payment_fees_account ||= subledger.accounts.new_or_create(id: cached_get_setup['payment_fees_account_id'])
  end

  def get_referrer_ap_category
    @referrer_ap_category ||= subledger.category.read(id: cached_get_setup['referrer_ap_category_id'])
  end

  def get_publisher_ap_category
    @publisher_ap_category ||= subledger.category.read(id: cached_get_setup['publisher_ap_category_id'])
  end

  def get_distributor_ap_category
    @distributor_ap_category ||= subledger.category.read(id: cached_get_setup['distributor_ap_category_id'])
  end

  def to_subledger_account_id(third_party_account_id, account_type, normal_balance)
    # replace chars on account id for readability
    third_party_account_id = third_party_account_id.tr("[@,.]", "_")

    # calculate the third party account key
    third_party_account_key = "#{third_party_account_id}_#{account_type.to_s}"
    
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
        when :referrer_accounts_payable
          get_referrer_ap_category.attach account: account
        when :publisher_accounts_payable
          get_publisher_ap_category.attach account: account
        when :distributor_accounts_payable
          get_distributor_ap_category.attach account: account
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

  def create_report(granular_escrow_account, granular_revenue_account, payment_fees_account
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

    referrer_ap_category = @subledger.categories.create
      description: 'Referrer Accounts Payable',
      normal_balance: @subledger.credit,
      version: 1

    publisher_ap_category = @subledger.categories.create
      description: 'Publisher Accounts Payable',
      normal_balance: @subledger.credit,
      version: 1

    distributor_ap_category = @subledger.categories.create
      description: 'Distributor Accounts Payable',
      normal_balance: @subledger.credit,
      version: 1

    # attach global accounts to categories
    cash_category.attach    account: granular_escrow_account
    revenue_category.attach account: granular_revenue_account
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

    balance_sheet.attach category: ap_category,
                         parent:   liabilities_category

    balance_sheet.attach category: referrer_ap_category,
                         parent:   ap_category

    balance_sheet.attach category: publisher_ap_category,
                         parent:   ap_category

    balance_sheet.attach category: distributor_ap_category,
                         parent:   ap_category

    return [referrer_ap_category.id, publisher_ap_category.id, distributor_ap_category.id]
  end

end
