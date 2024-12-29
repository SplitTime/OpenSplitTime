class Lotteries::EntrantServiceDetailParameters < BaseParameters
  def self.permitted
    [
      :form_accepted_at,
      :form_accepted_comments,
      :form_rejected_at,
      :form_rejected_comments,
      :completed_date,
    ]
  end
end
