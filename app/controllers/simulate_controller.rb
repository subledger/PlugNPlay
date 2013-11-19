class SimulateController < ApplicationController

  def index
  end

  def buy_ticket
  end

  def invoice_customer
    invoice = params[:invoice]
    invoice_value = BigDecimal.new(invoice[:value])
    usaw_value = (invoice_value - sport_ngin_fee) * usaw_rate
    minnesota_value = (invoice_value - sport_ngin_fee) * minnesota_rate

    money_service.invoice_customer(
      customer_id: invoice[:customer_id],
      invoice_value: invoice_value,
      sportngin_value: sport_ngin_fee,
      organizations_values: [
        { account_id: "usaw", value: usaw_value },
        { account_id: "minnesota", value: minnesota_value }
      ],
      reference_url: invoice[:reference_url],
      description: invoice[:description]
    )
  end

  def pay_customer_invoice
  end

  def customer_invoice_payed
    invoice = params[:invoice]
    invoice_value = BigDecimal.new(invoice[:value])

    money_service.customer_invoice_payed(
      customer_id: invoice[:customer_id],
      invoice_value: invoice_value,
      reference_url: invoice[:reference_url],
      description: invoice[:description]
    )
  end

private
  def sport_ngin_fee
    10
  end

  def usaw_rate
    0.6
  end

  def minnesota_rate
    0.4
  end

  def money_service
    @money_service ||= MoneyService.new
  end
end
