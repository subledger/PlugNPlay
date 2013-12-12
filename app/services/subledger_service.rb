class SubledgerService

  def initialize()
  end

  def subledger
    @subledger ||= Subledger.new(cached_get_setup.slice("key_id", "identity_id", "secret", "org_id", "book_id").symbolize_keys)
  end

  # create the journal entries related to invoicing a Sport Ngin customer:
  # - debit account receivable from customer
  # - credit organizations accounts payable
  # - credit revenue account from Sport Ngin
  def invoice_customer(transaction_id, customer_id, invoice_value, sportngin_value, organizations_values, reference_url, description)
    # prepare the journal entrie lines
    je_lines = []

    # customer line
    je_lines << {
      account: to_subledger_account_id(customer_id, :accounts_receivable, subledger.debit),
      value: subledger.debit(invoice_value)
    }

    # sport ngin line
    je_lines << {
      account: get_revenue_account,
      value: subledger.credit(sportngin_value)
    }

    # organiations lines
    organizations_values.each do |organization|
      je_lines << {
        account: to_subledger_account_id(organization[:account_id], :accounts_payable, subledger.credit),
        value: subledger.credit(organization[:value])
      }
    end

    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        je_lines
    )

    # map transaction id
    if transaction_id.present?
      Mapping.map_entity("transaction::invoice_customer", transaction_id, result.id)
    end

    return result
  end

  # create the journal entries related to receiving payment from a Sport Ngin
  # customer:
  # - debit cash account from Sport Ngin
  # - credit customer accounts receivable account
  def customer_invoice_payed(transaction_id, customer_id, invoice_value, reference_url, description)
    result = subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: get_cash_account,
          value:   subledger.debit(invoice_value)
        },
        {
          account: to_subledger_account_id(customer_id, :accounts_receivable, subledger.debit),
          value:  subledger.credit(invoice_value)
        }
      ]
    )

    # map transaction id
    if transaction_id.present?
      Mapping.map_entity("transaction::customer_invoice_payed", transaction_id, result.id)
    end

    return result
  end

  def cached_get_setup
    Rails.cache.fetch(["subledger", "setup"]) { get_setup }
  end

  def get_setup
    return {
      "key_id"             => AppConfig.get_value("SUBLEDGER_KEY_ID"),
      "identity_id"        => AppConfig.get_value("SUBLEDGER_IDENTITY_ID"),
      "secret"             => AppConfig.get_value("SUBLEDGER_SECRET"),
      "org_id"             => AppConfig.get_value("SUBLEDGER_ORG_ID"),
      "book_id"            => AppConfig.get_value("SUBLEDGER_BOOK_ID"),
      "revenue_account_id" => AppConfig.get_value("SUBLEDGER_REVENUE_ACCOUNT_ID"),
      "cash_account_id"    => AppConfig.get_value("SUBLEDGER_CASH_ACCOUNT_ID"),
      "ar_category_id"     => AppConfig.get_value("SUBLEDGER_AR_CATEGORY_ID"),
      "ap_category_id"     => AppConfig.get_value("SUBLEDGER_AP_CATEGORY_ID")
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
    revenue_account = create_global_account(
      "Revenue Account",
      "http://www.sportngin.com",
       @subledger.credit
    )

    cash_account = create_global_account(
      "Cash Account",
      "http://www.sportngin.com",
      @subledger.debit
    )

    # create report
    ar_category_id, ap_category_id = create_report(revenue_account, cash_account)

    # evict own cache
    evict_cache

    result = {
      "SUBLEDGER_KEY_ID"             => key.id,
      "SUBLEDGER_IDENTITY_ID"        => identity.id,
      "SUBLEDGER_SECRET"             => key.secret,
      "SUBLEDGER_ORG_ID"             => org.id,
      "SUBLEDGER_BOOK_ID"            => book.id,
      "SUBLEDGER_REVENUE_ACCOUNT_ID" => revenue_account.id,
      "SUBLEDGER_CASH_ACCOUNT_ID"    => cash_account.id,
      "SUBLEDGER_AR_CATEGORY_ID"     => ar_category_id,
      "SUBLEDGER_AP_CATEGORY_ID"     => ap_category_id
    }

    block_given? ? yield(result) : result
  end

private
  def get_revenue_account
    @revenue_account ||= subledger.accounts.new_or_create(id: cached_get_setup["revenue_account_id"])
  end

  def get_cash_account
    @cash_account ||= subledger.accounts.new_or_create(id: cached_get_setup['cash_account_id'])
  end

  def get_ar_category
    @ar_category ||= subledger.category.read(id: cached_get_setup['ar_category_id'])
  end

  def get_ap_category
    @ap_category ||= subledger.category.read(id: cached_get_setup['ap_category_id'])
  end

  def to_subledger_account_id(third_party_account_id, account_type, normal_balance)
    # calculate the third party account key
    third_party_account_key = "#{third_party_account_id}::#{account_type.to_s}"
    
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
        when :accounts_receivable
          get_ar_category.attach account: account

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

  def create_report(revenue_account, cash_account)
    Rails.logger.info "  - Creating Report..."

    # create categories
    assets_category = @subledger.categories.create description: 'Assets',
                                                   normal_balance: @subledger.debit,
                                                   version: 1

    liabilities_category = @subledger.categories.create description: 'Liabilities',
                                                        normal_balance: @subledger.credit,
                                                        version: 1

    ar_category = @subledger.categories.create description: 'Accounts Receivable',
                                               normal_balance: @subledger.debit,
                                               version: 1

    ap_category = @subledger.categories.create description: 'Accounts Payable',
                                               normal_balance: @subledger.credit,
                                               version: 1

    revenue_category = @subledger.categories.create description: 'Revenue',
                                                    normal_balance: @subledger.credit,
                                                    version: 1

    cash_category = @subledger.categories.create description: 'Cash',
                                                 normal_balance: @subledger.debit,
                                                 version: 1

    # attach global accounts to categories
    revenue_category.attach account: revenue_account
    cash_category.attach account: cash_account

    # create the report
    balance_sheet = @subledger.report.create description: 'Snap-shot Report'

    # attach categories to report
    balance_sheet.attach category: assets_category
    balance_sheet.attach category: liabilities_category
    balance_sheet.attach category: revenue_category

    balance_sheet.attach category: cash_category,
                         parent:   assets_category

    balance_sheet.attach category: ar_category,
                         parent:   assets_category

    balance_sheet.attach category: ap_category,
                         parent:   liabilities_category

    return ar_category.id, ap_category.id
  end

end
