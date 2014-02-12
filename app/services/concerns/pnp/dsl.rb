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
  
        # optional parameters
        category_id = config[:category_id]
  
        # get subledger id calculated from config
        to_subledger_config = config.slice(:sufixes, :prefixes)
        subledger_id, key = to_subledger_id :account, id, to_subledger_config
       
        # instantiate/create the account
        data = { id: subledger_id, description: CGI::escape(key) }
        data = data.merge config.slice(:description, :normal_balance)

        subledger.accounts.new_or_create(data) do |account|  
          unless Mapping.entity_map_exists?(:account, key)
            # update cache and file if this is a new account
            Mapping.map_entity(:account, key, account.id)
  
            # attach to a report category category, if one was provided
            if category_id.present?
              attach_account_to_category account, category_id
            end
          end

          account
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
  
      # config = :id, :normal_balance
      def category(id, config = {})
        config = config.symbolize_keys

        # required parameters
        id = id.to_sym
  
        # get subledger id calculated from config
        subledger_id, key = to_subledger_id(:category, id)
  
        if subledger_id.present?
          subledger.categories.read id: subledger_id

        else
          # prepare category data
          data = { description: "Category #{id.to_s.humanize}", version: 1 }
          data = data.merge config.slice(:description, :normal_balance, :version)

          Rails.logger.info data

          # create the category
          the_category = subledger.categories.create data

          # save new mapping
          Mapping.map_entity("category", key, the_category.id)
  
          return the_category
        end
      end
  
      def report(id, config = {})
        config = config.symbolize_keys

        # required parameters
        id = id.to_sym
  
        # get calculated Subledger id
        subledger_id, key = to_subledger_id :report, id
  
        if subledger_id.present?
          # return the report if already mapped
          subledger.reports.read id: subledger_id
  
        else
          # prepare report data
          data = { description: "Report #{id.to_s.humanize}" }
          data = data.merge config.slice :description

          # create the report
          the_report = subledger.reports.create data
            
          # save new mapping
          Mapping.map_entity(:report, key, the_report.id)
  
          return the_report
        end
      end

      def attach_category_to_report(category_id, report_id, config = {})
        parent_category_id = config[:parent_category_id]

        # attaching data
        data = { category: category(category_id) }
        data[:parent] = category(parent_category_id) if parent_category_id.present?

        # attach it
        report(report_id).attach data
      end

      def attach_account_to_category(account, category_id)
        category(category_id).attach account: account
      end
  
      def line(account, amount)
        { account: account, value: amount }
      end
  
      def credit_line(config)
        line config[:account], credit(config[:amount])
      end
  
      def debit_line(config)
        line config[:account], debit(config[:amount])
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
        normal_config = { prefixes: [], sufixes: [] }
        config = normal_config.merge config

        # replace chars on account id for readability
        id = id.to_s.tr("[@,.]", "_")
  
        # calculate the third party account key
        key = (config[:prefixes] + [id] + config[:sufixes]).join "_"
  
        # get the subledger account id
        subledger_id = Mapping.entity_map_value(what, key)
  
        return subledger_id, key
      end
    end
  end
end
