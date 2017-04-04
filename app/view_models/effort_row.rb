class EffortRow
  ULTRASIGNUP_STATUS_TABLE = {'Finished' => 1, 'Dropped' => 2, 'Not Started' => 3}
  include PersonalInfo

  attr_reader :effort, :participant
  delegate :id, :name, :first_name, :last_name, :gender, :bib_number, :age, :city, :state_code, :country_code,
           :bad?, :questionable?, :segment_seconds, :overall_rank, :gender_rank, :birthdate, :start_time,
           :final_distance, :final_split_name, :final_time, :final_lap, :multiple_laps?, :lap, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort,
                           exclusive: [:effort, :participant, :multi_lap], class: self.class)
    @effort = args[:effort]
    @participant = args[:participant]
  end

  def final_lap_split_name
    multiple_laps? ? "#{final_split_name} Lap #{final_lap}" : final_split_name
  end

  def final_day_and_time
    start_time + final_time
  end

  def year_and_lap
    multiple_laps? ? "#{start_time.year} / Lap #{lap}" : "#{start_time.year}"
  end

  def run_status
    case
    when effort.finished?
      'Finished'
    when effort.dropped?
      'Dropped'
    when effort.in_progress?
      'In Progress'
    else
      'Not Started'
    end
  end

  def ultrasignup_finish_status
    ULTRASIGNUP_STATUS_TABLE[run_status] || "#{name} (id: #{id}, bib: #{bib_number}) is in progress"
  end
end
