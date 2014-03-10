class Api::V1::BalanceSerializer < ActiveModel::Serializer
  has_one :debit_value , serializer: Api::V1::ValueSerializer
  has_one :credit_value, serializer: Api::V1::ValueSerializer
  has_one :value       , serializer: Api::V1::ValueSerializer
end
