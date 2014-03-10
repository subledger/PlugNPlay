class Api::V1::LineSerializer < ActiveModel::Serializer
  attribute :id
  attribute :journal_entry
  attribute :account
  attribute :description
  attribute :version
  attribute :effective_at
  attribute :posted_at

  has_one   :value  , serializer: Api::V1::ValueSerializer
  has_one   :balance, serializer: Api::V1::BalanceSerializer

  def journal_entry
    object.journal_entry.id
  end

  def account
    object.account.id
  end
end
