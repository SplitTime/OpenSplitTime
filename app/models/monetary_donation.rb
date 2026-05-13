class MonetaryDonation < ApplicationRecord
  has_paper_trail

  belongs_to :organization

  enum :source, { paypal: "paypal", check: "check", bitpay: "bitpay", other: "other" }

  validates :received_on, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :source, presence: true
end
