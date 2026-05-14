class MonetaryDonationResource < Madmin::Resource
  attribute :id, form: false
  attribute :organization, index: true
  attribute :received_on, index: true
  attribute :amount, index: true
  attribute :source, index: true
  attribute :note, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false

  def self.display_name(record)
    amount = ActiveSupport::NumberHelper.number_to_currency(record.amount)
    "#{record.organization.name} — #{amount} on #{record.received_on}"
  end

  def self.default_sort_column
    "received_on"
  end

  def self.default_sort_direction
    "desc"
  end
end
