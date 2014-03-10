class Api::V1::ValueSerializer < ActiveModel::Serializer
  attribute :type
  attribute :amount
end
