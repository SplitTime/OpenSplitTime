class Lotteries::EntrantServiceDetail < ApplicationRecord
  self.table_name = "lotteries_entrant_service_details"

  belongs_to :entrant, class_name: "LotteryEntrant", foreign_key: "lottery_entrant_id"
  has_one_attached :completed_form

  validates_with Lotteries::EntrantServiceDetailValidator
  validates :completed_form,
            content_type: { in: %w[image/png image/jpeg application/pdf], message: "must be a pdf, jpeg, or png file" },
            size: { less_than: 5.megabytes, message: "must be less than 5 megabytes" }

  delegate :first_name, :last_name, :full_name, :organization, :lottery, to: :entrant

  def accepted?
    form_accepted_at?
  end

  def rejected?
    form_rejected_at?
  end

  def under_review?
    !accepted? && !rejected?
  end

  def status
    case
    when accepted?
      "accepted"
    when rejected?
      "rejected"
    else
      "under_review"
    end
  end
end
