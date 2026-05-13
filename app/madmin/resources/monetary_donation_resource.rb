class MonetaryDonationResource < Madmin::Resource
  attribute :id, form: false
  attribute :organization
  attribute :received_on
  attribute :amount
  attribute :source
  attribute :note
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
