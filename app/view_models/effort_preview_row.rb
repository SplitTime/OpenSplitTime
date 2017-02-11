class EffortPreviewRow
  include PersonalInfo

  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bio, to: :effort

  def initialize(effort)
    @effort = effort
  end

  def participant
    Participant.new(id: effort.participant_id) if effort.participant_id
  end

  private

  attr_reader :effort

end