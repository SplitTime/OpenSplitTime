class LotteryEntrantParameters < BaseParameters
  def self.csv_export_attributes
    %w[
      division_name
      first_name
      last_name
      gender
      birthdate
      email
      phone
      city
      state
      country
      number_of_tickets
      pre_selected
      external_id
    ]
  end

  def self.mapping
    lottery_entrant_mapping = {
      "external": :external_id,
      tickets: :number_of_tickets,
      "#_of_tickets": :number_of_tickets,
      "#_tickets": :number_of_tickets,
    }

    ::EffortParameters.mapping.merge(lottery_entrant_mapping)
  end

  def self.permitted
    [
      :birthdate,
      :city,
      :country_code,
      :division,
      :email,
      :external_id,
      :first_name,
      :gender,
      :id,
      :last_name,
      :lottery_division_id,
      :number_of_tickets,
      :phone,
      :pre_selected,
      :state_code,
      :withdrawn,
    ]
  end
end
