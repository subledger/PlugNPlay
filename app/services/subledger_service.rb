require 'yaml'
require 'thread'

class SubledgerService

  def initialize()
    return unless ENV['SUBLEDGER_KEY_ID'].present?

    # instantiate subledger api client
    @subledger = Subledger.new :key_id      => ENV['SUBLEDGER_KEY_ID'],
                               :identity_id => ENV['SUBLEDGER_IDENTITY_ID'],
                               :secret      => ENV['SUBLEDGER_SECRET'],
                               :org_id      => ENV['SUBLEDGER_ORG_ID'],
                               :book_id     => ENV['SUBLEDGER_BOOK_ID']

    # load subledger accounts map
    @mutex = Mutex.new
    load_accounts_map
  end

  def subledger
    @subledger
  end

  # create the journal entries related to invoicing a Sports Ngin customer:
  # - debit account receivable from customer
  # - credit organizations accounts payable
  # - credit revenue account from Sports Ngin
  def invoice_customer(customer_id, invoice_value, sportsngin_value, organizations_values, reference_url, description)
    # prepare the journal entrie lines
    je_lines = []

    # customer line
    je_lines << {
      account: to_subledger_account_id(customer_id, :accounts_receivable, @subledger.debit),
      value: @subledger.debit(invoice_value)
    }

    # sports ngin line
    je_lines << {
      account: get_revenue_account,
      value: @subledger.credit(sportsngin_value)
    }

    # organiations lines
    organizations_values.each do |organization|
      je_lines << {
        account: to_subledger_account_id(organization[:account_id], :accounts_payable, @subledger.credit),
        value: @subledger.credit(organization[:value])
      }
    end

    return @subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        je_lines
    )
  end

  # create the journal entries related to receiving payment from a Sports Ngin
  # customer:
  # - debit cash account from Sports Ngin
  # - credit customer accounts receivable account
  def customer_invoice_payed(customer_id, invoice_value, reference_url, description)
    return @subledger.journal_entry.create_and_post(
      effective_at: Time.now,
      description:  description,
      reference:    reference_url,
      lines:        [
        {
          account: get_cash_account,
          value:   @subledger.debit(invoice_value)
        },
        {
          account: to_subledger_account_id(customer_id, :accounts_receivable, @subledger.debit),
          value:  @subledger.credit(invoice_value)
        }
      ]
    )
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
      "http://www.sportsngin.com",
       @subledger.credit
    )

    cash_account = create_global_account(
      "Cash Account",
      "http://www.sportsngin.com",
      @subledger.debit
    )

    # create report
    ar_category_id, ap_category_id = create_report(revenue_account, cash_account)

    puts "\n* You are all set!"
    puts "* Just add/set the the following environment variables and restart your app:"
    puts "SUBLEDGER_KEY_ID='#{key.id}'"
    puts "SUBLEDGER_SECRET='#{key.secret}'"
    puts "SUBLEDGER_ORG_ID='#{org.id}'"
    puts "SUBLEDGER_BOOK_ID='#{book.id}'"
    puts "SUBLEDGER_REVENUE_ACCOUNT_ID='#{revenue_account.id}'"
    puts "SUBLEDGER_CASH_ACCOUNT_ID='#{cash_account.id}'"
    puts "SUBLEDGER_AR_CATEGORY_ID='#{ar_category_id}'"
    puts "SUBLEDGER_AP_CATEGORY_ID='#{ap_category_id}'"

    puts "\n* We will also map your app customer and organizations accounts"
    puts "to Subledger specific accounts. For this to work, we will need to"
    puts "create an YAML file. Please specify the full file path in an env"
    puts "variable:"
    puts "SUBLEDGER_ACCOUNTS_MAPPING_FILE=''"
    puts "\nExample: "
    puts "SUBLEDGER_ACCOUNTS_MAPPING_FILE='/opt/myapp/config/subledger_accounts_mapping.yml'"

    puts "\nAll done. Enjoy!"
  end

  def accounts_map
    @accounts_map
  end

  def load_accounts_map
    @mutex.synchronize do
      File.open( ENV['SUBLEDGER_ACCOUNTS_MAPPING_FILE'], 'a+' ) do |yf|
        @accounts_map = YAML.load(yf) || {}
      end
    end
  end

  def add_accounts_mapping(third_party_account_key, subledger_account_id)
    @mutex.synchronize do
      # update the memory cache
      @accounts_map[third_party_account_key] = subledger_account_id
      
      # rewrite the mapping file
      File.open(ENV['SUBLEDGER_ACCOUNTS_MAPPING_FILE'], 'w') do |yf|
        YAML.dump(@accounts_map, yf)
      end
    end
  end

private
  def get_revenue_account
    @revenue_account ||= @subledger.accounts.new_or_create(id: ENV['SUBLEDGER_REVENUE_ACCOUNT_ID'])
  end

  def get_cash_account
    @cash_account ||= @subledger.accounts.new_or_create(id: ENV['SUBLEDGER_CASH_ACCOUNT_ID'])
  end

  def get_ar_category
    @ar_category ||= @subledger.category.read(id: ENV['SUBLEDGER_AR_CATEGORY_ID'])
  end

  def get_ap_category
    @ap_category ||= @subledger.category.read(id: ENV['SUBLEDGER_AP_CATEGORY_ID'])
  end

  def to_subledger_account_id(third_party_account_id, account_type, normal_balance)
    # calculate the third party account key
    third_party_account_key = "#{third_party_account_id}::#{account_type.to_s}"
    
    # get the subledger account id
    account_id = @accounts_map[third_party_account_key]

    # instantiate/create the account
    return @subledger.accounts.new_or_create(
      id: account_id,
      description: third_party_account_key,
      normal_balance: normal_balance) do |account|

      # update cache and file if this is a new account
      unless @accounts_map.has_key? third_party_account_key
        add_accounts_mapping(third_party_account_key, account.id)

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
    puts "  - Creating Identity..."
    @subledger.identities.create email:       email,
                                 description: description
  end

  def create_org(description)
    puts "  - Creating Org..."
    @subledger.orgs.create description: description
  end

  def create_book(org, description)
    puts "  - Creating Book..."
    @subledger.books.create org:         org,
                           description: description
  end

  def create_global_account(description, reference, normal_balance)
    puts "  - Creating Global Account..."
    @subledger.account.create description:    description,
                              reference:      reference,
                              normal_balance: normal_balance
  end 

  def create_report(revenue_account, cash_account)
    puts "  - Creating Report..."

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
    revenue_category.attach account: get_revenue_account
    cash_category.attach account: get_cash_account

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
