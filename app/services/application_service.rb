class ApplicationService
  include Pnp::Dsl

  ### base subledger methods

  def user_balance(data)
    user_id = data[:user_id]
    at      = data[:at].present? ? data[:at].to_time : Time.now

    begin
      account(user_id, data.slice(:sufixes, :prefixes)).balance({
        at: at
      })
    rescue Subledger::Domain::AccountError => e
      # if account does not exist, return an empty balance
      Subledger::Domain::Balance.new
    end
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

    begin
      account(user_id, data.slice(:sufixes, :prefixes)).lines(config)
    rescue Subledger::Domain::AccountError => e
      # f account does not exist, return an empty list of lines
      []
    end
  end
end
