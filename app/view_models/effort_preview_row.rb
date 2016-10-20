class EffortPreviewRow
  include PersonalInfo

  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bio, to: :effort

  attr_reader :participant

  def initialize(effort, options = {})
    @effort = effort
    @participant = options[:participant]
  end

  private

  attr_reader :effort

end