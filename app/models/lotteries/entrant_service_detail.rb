# frozen_string_literal: true

class Lotteries::EntrantServiceDetail < ApplicationRecord
  self.table_name = "lotteries_entrant_service_details"

  belongs_to :entrant, class_name: "LotteryEntrant", foreign_key: "lottery_entrant_id"
  has_one_attached :completed_form

  validates :completed_form,
            content_type: { in: %w[image/png image/jpeg application/pdf], message: "must be a pdf, png, or jpeg file" },
            size: { less_than: 2.megabytes, message: "must be less than 2 megabytes" }

  delegate :first_name, :last_name, :full_name, :organization, :lottery, to: :entrant

  def accepted?
    form_accepted_at?
  end

  def rejected?
    form_rejected_at?
  end
end
