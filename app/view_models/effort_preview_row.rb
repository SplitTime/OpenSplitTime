class EffortPreviewRow
  include PersonalInfo

  attr_reader :effort
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bio, :participant, to: :effort

  def initialize(effort)
    @effort = effort
  end
end