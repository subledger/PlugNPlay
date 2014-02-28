class SetupService < ApplicationService
  knows_accounting

  def get_setup_configs
    creds_keys = ['key_id', 'secret', 'identity_id', 'org_id', 'book_id']
    AppConfig.where("app_configs.key in (?)", creds_keys)
  end

  def get_setup
    setup = {}
    get_setup_configs.each do |app_config|
      setup[app_config.key] = app_config.value
    end

    setup
  end

  def setup_ready?
    get_setup_configs.count == 5
  end

  def initial_setup(config)
    Rails.logger.info "* Initializing Subledger PlugNPlay setup\n"

    email         = config[:email]
    identity_desc = config[:identity_desc]
    org_desc      = config[:org_desc]
    book_desc     = config[:book_desc]

    Rails.logger.info "======================================================"
    Rails.logger.info "- Email: #{email}"
    Rails.logger.info "- Identity Description: #{identity_desc}"
    Rails.logger.info "- Organization Description: #{org_desc}"
    Rails.logger.info "- Book Description: #{book_desc}"
    Rails.logger.info "======================================================\n"

    # create/get the identity
    create_identity email, identity_desc

    # create org
    create_org org_desc

    # create book
    create_book book_desc

    # create global accounts
    create_global_accounts

    # create categories
    create_categories

    # create reports
    create_reports
  end

  def create_identity(email, description)
    # create identity
    Rails.logger.info "- Creating Identity..."

    key_id      = AppConfig.get_value("key_id")
    secret      = AppConfig.get_value("secret")
    identity_id = AppConfig.get_value("identity_id")

    unless key_id.present? and secret.present? and identity_id.present?
      AppConfig.transaction do
        # delete existing credentials
        creds_keys = ["key_id", "secret", "identity_id", "org_id", "book_id"]
        AppConfig.where("app_configs.key in (?)", creds_keys).destroy_all

        # (re)create the credentials
        identity, key = subledger(true).identities.create email:       email,
                                                          description: description

        # asve to app config
        AppConfig.create! key: "key_id"     , value: key.id
        AppConfig.create! key: "secret"     , value: key.secret
        AppConfig.create! key: "identity_id", value: identity.id

        key_id = key.id
        secret = key.secret
        identity_id = identity.id
      end
    end
    
    [key_id, secret, identity_id]
  end

  def create_org(description)
    Rails.logger.info "- Creating Org..."

    org_id = AppConfig.get_value("org_id")

    unless org_id.present?
      AppConfig.transaction do
        # delete existing credentials
        creds_keys = ["org_id", "book_id"]
        AppConfig.where("app_configs.key in (?)", creds_keys).destroy_all

        # create the org
        org = subledger(true).orgs.create description: description

        # save to app config
        AppConfig.create! key: "org_id", value: org.id

        org_id = org.id
      end
    end

    org_id
  end

  def create_book(description)
    Rails.logger.info "- Creating Book..."

    book_id = AppConfig.get_value("book_id")

    unless book_id.present?
      AppConfig.transaction do
        # delete existing book id, if any
        AppConfig.where("app_configs.key = ?", "book_id").destroy_all

        # (re)create the book
        book = subledger(true).books.create description: description

        # save to app config
        AppConfig.create! key: "book_id", value: book.id

        book_id = book.id
      end
    end

    reset_subledger

    book_id
  end

  def create_global_accounts
    Rails.logger.info "- Creating Global Accounts..."

    global_accounts = []
    global_accounts << global_account(:escrow      , normal_balance: debit )
    global_accounts << global_account(:revenue     , normal_balance: credit)
    global_accounts << global_account(:ap_stripe   , normal_balance: credit)

    global_accounts
  end

  def create_categories
    Rails.logger.info "- Creating Categories..."

    categories = []
    categories << category(:assets                   , normal_balance: debit )
    categories << category(:cash                     , normal_balance: debit )
    categories << category(:revenue                  , normal_balance: credit)
    categories << category(:liabilities              , normal_balance: credit)
    categories << category(:accounts_payable         , normal_balance: credit)
    categories << category(:accounts_receivable      , normal_balance: debit )
    categories << category(:unearned_revenue         , normal_balance: credit)
    categories << category(:unused_balance           , normal_balance: credit)
    categories << category(:unused_balance_processing, normal_balance: credit)

    categories
  end

  def create_reports
    Rails.logger.info "- Creating Reports..."

    reports = []

    # create the report
    reports << report(:balance, description: "Chart of Accounts")

    # attach the main categories
    attach_category_to_report :assets     , :balance
    attach_category_to_report :revenue    , :balance
    attach_category_to_report :liabilities, :balance

    # attach the subcategories
    attach_category_to_report :cash                     , :balance, parent_category_id: :assets
    attach_category_to_report :accounts_payable         , :balance, parent_category_id: :liabilities
    attach_category_to_report :accounts_receivable      , :balance, parent_category_id: :assets
    attach_category_to_report :unearned_revenue         , :balance, parent_category_id: :liabilities
    attach_category_to_report :unused_balance           , :balance, parent_category_id: :unearned_revenue
    attach_category_to_report :unused_balance_processing, :balance, parent_category_id: :unearned_revenue

    # attach global accounts to categories
    attach_account_to_category(global_account(:escrow)   , :cash           )
    attach_account_to_category(global_account(:revenue)  , :revenue        )

    reports
  end
end
