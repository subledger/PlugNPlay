module Pnp
  module Dsl
    extend ActiveSupport::Concern
  
    included do
    end
  
    module ClassMethods
      def knows_accounting
        include Pnp::Dsl::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def subledger(force_new = false)
        @subledger = nil if force_new

        unless @subledger.present?
          key_id      = AppConfig.get_value("key_id"     )
          identity_id = AppConfig.get_value("identity_id"),
          secret      = AppConfig.get_value("secret"     ),
          org_id      = AppConfig.get_value("org_id"     ),
          book_id     = AppConfig.get_value("book_id"    )

          creds = {}
          creds[:key_id]      = key_id      if key_id.present?
          creds[:identity_id] = identity_id if identity_id.present?
          creds[:secret]      = secret      if secret.present?
          creds[:org_id]      = org_id      if org_id.present?
          creds[:book_id]     = book_id     if book_id.present?

          @subledger = Subledger.new(creds)
        end

        @subledger
      end

      def reset_subledger
        @subledger = nil
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
  
        # get subledger id calculated from config
        to_subledger_config = config.slice(:sufixes, :prefixes)
        subledger_id, key = to_subledger_id :account, id, to_subledger_config

        Rails.cache.fetch ["pnp", "dsl", "account", key] do
          the_account = nil

          if subledger_id.present?
            the_account = subledger.accounts.read id: subledger_id

            # attach to a category, if one is present
            if config[:category_id].present?
              attach_account_to_category the_account, config[:category_id]
            end

          else
            # prepare the data
            data = { id: subledger_id, description: CGI::escape(key) }
            data = data.merge config.slice(:description, :normal_balance)

            # create the account
            the_account = subledger.accounts.create data

            # map it
            Mapping.map_entity(:account, key, the_account.id)

            # attach to a category, if one is present
            if config[:category_id].present?
              attach_account_to_category the_account, config[:category_id]
            end
          end

          return the_account
        end
      end
  
      def global_account(id, config = {})
        normal_config = { prefixes: [:global], sufixes: [] }

        if config[:role].present?
          normal_config[:sufixes].unshift config[:role]
        end

        account id, normal_config.merge(config)
      end
  
      def account_receivable(id, config = {})
        normal_config = { normal_balance: credit, sufixes: [:accounts_receivable] }

        if config[:role].present?
          normal_config[:sufixes].unshift config[:role]
        end

        account id, normal_config.merge(config)
      end
  
      def account_payable(id, config = {})
        normal_config = { normal_balance: debit, sufixes: [:accounts_payable] }

        if config[:role].present?
          normal_config[:sufixes].unshift config[:role]
        end

        account id, normal_config.merge(config)
      end
  
      def category(id, config = {})
        config = config.symbolize_keys

        # required parameters
        id = id.to_sym
  
        # get subledger id calculated from config
        subledger_id, key = to_subledger_id(:category, id)

        Rails.cache.fetch ["pnp", "dsl", "category", key] do
          the_category = nil

          if subledger_id.present?
            the_category = subledger.categories.read id: subledger_id

          else
            # prepare category data
            data = { description: id.to_s.humanize, version: 1 }
            data = data.merge config.slice(:description, :normal_balance, :version)

            # create the category
            the_category = subledger.categories.create data

            # save new mapping
            Mapping.map_entity("category", key, the_category.id)
          end
  
          return the_category
        end
      end
  
      def report(id, config = {})
        config = config.symbolize_keys

        # required parameters
        id = id.to_sym
  
        # get calculated Subledger id
        subledger_id, key = to_subledger_id :report, id

        Rails.cache.fetch ["pnp", "dsl", "report", key] do
          the_report = nil

          if subledger_id.present?
            # return the report if already mapped
            the_report = subledger.reports.read id: subledger_id
  
          else
            # prepare report data
            data = { description: "Report #{id.to_s.humanize}" }
            data = data.merge config.slice :description

            # create the report
            the_report = subledger.reports.create data
              
            # save new mapping
            Mapping.map_entity(:report, key, the_report.id)
          end
  
          return the_report
        end
      end

      def attach_category_to_report(category_id, report_id, config = {})
        id = "#{category_id}_#{report_id}".to_sym
        mapping_id, key = to_subledger_id :category_report, id

        unless mapping_id.present?
          parent_category_id = config[:parent_category_id]

          # attaching data
          data = { category: category(category_id) }
          data[:parent] = category(parent_category_id) if parent_category_id.present?

          # attach
          report(report_id).attach data

          Mapping.map_entity :category_report, key, "already attached"
        end
      end

      def attach_account_to_category(account, category_id)
        id = "#{account.id}_#{category_id}".to_sym
        mapping_id, key = to_subledger_id :account_category, id

        unless mapping_id.present?
          category(category_id).attach account: account
          Mapping.map_entity :account_category, key, "already attached"
        end
      end
  
      def line(account, amount, config)
        account_config = config.slice(:role, :category_id)
        
        if not account.present? and config[:global_account_id].present? 
          account = global_account config[:global_account_id], account_config
        end

        if not account.present? and config[:account_payable_id].present? 
          account = account_payable config[:account_payable_id], account_config
        end

        if not account.present? and config[:account_receivable_id].present? 
          account = account_receivable config[:account_receivable_id], account_config
        end

        if config[:callback].present?
          config[:callback].call(account, amount, config)
        end

        { account: account, value: amount }
      end
  
      def credit_line(config)
        line config[:account], credit(config[:amount]), config
      end
  
      def debit_line(config)
        line config[:account], debit(config[:amount]), config
      end
  
      def post_transaction(transaction, transaction_id, lines, config = {})
        result = subledger.journal_entry.create_and_post(
          effective_at: config[:effective_at] || Time.now,
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

      def to_subledger_id(what, id, config = {})
        # calculate the third party account key
        key = to_third_party_key(id, config)
  
        # get the subledger account id
        subledger_id = Mapping.entity_map_value(what, key)
  
        return subledger_id, key
      end

      def to_third_party_key(id, config = {})
        normal_config = { prefixes: [], sufixes: [] }
        config = normal_config.merge config

        # replace chars on account id for readability
        id = id.to_s.tr("[@,.]", "_")

        (config[:prefixes] + [id] + config[:sufixes]).join "_"
      end
    end
  end
end
