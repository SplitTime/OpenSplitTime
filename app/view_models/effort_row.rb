class EffortRow
  include PersonalInfo

  attr_reader :overall_place, :gender_place, :finish_status, :start_time
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, to: :effort

  def initialize(effort, options = {})
    @effort = effort
    @overall_place = options[:overall_place]
    @gender_place = options[:gender_place]
    @finish_status = options[:finish_status]
    @start_time = options[:start_time]
  end

  def year
    start_time ? effort.start_time.year : nil
  end

  def finish_time
    (finish_status && finish_status.is_a?(Numeric)) ? finish_status : nil
  end

  private

  attr_reader :effort

end