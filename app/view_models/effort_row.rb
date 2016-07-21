class EffortRow
  include PersonalInfo

  attr_reader :overall_place, :gender_place, :finish_status, :run_status, :dropped_split_name, :day_and_time, :start_time_from_params
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :city, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :bio, :birthdate, to: :effort

  def initialize(effort, options = {})
    @effort = effort
    @overall_place = options[:overall_place]
    @gender_place = options[:gender_place]
    @finish_status = options[:finish_status]
    @run_status = options[:run_status]
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

  def effort_id
    effort.id
  end

  def ultrasignup_finish_status
    case
      when finish_status.is_a?(Numeric)
        1
      when finish_status.include?("Dropped")
        2
      when finish_status.include?("DNS")
        3
      else
        raise "Problem with finish status for effort id #{effort_id}"
    end
  end

  private

  attr_reader :effort

end