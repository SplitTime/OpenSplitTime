# frozen_string_literal: true

class LotteryParameters < BaseParameters
  def self.permitted
    [
      :calculation_class,
      :concealed,
      :id,
      :name,
      :scheduled_start_date,
      :service_form,
      :slug,
      :status,
    ]
  end

  def self.permitted_query
    permitted + LotteryEntrantParameters.permitted + LotteryTicketParameters.permitted
  end
end
