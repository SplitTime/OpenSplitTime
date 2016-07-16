class EffortRow
  include PersonalInfo

  attr_reader :overall_place, :gender_place, :finish_status, :dropped_split_name, :day_and_time, :start_time_from_params
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :bio, to: :effort

  def initialize(effort, options = {})
    @effort = effort
    @overall_place = options[:overall_place]
    @gender_place = options[:gender_place]
    @finish_status = options[:finish_status]
    @dropped_split_name = options[:dropped_split_name]
    @day_and_time = options[:day_and_time]
    @start_time_from_params = options[:start_time]
  end

  def effective_start_time
    start_time_from_params.try(:to_datetime) || effort.start_time
  end

  def year
    effective_start_time ? effective_start_time.year : nil
  end

  def finish_time
    (finish_status && finish_status.is_a?(Numeric)) ? finish_status : nil
  end

  private

  attr_reader :effort

end