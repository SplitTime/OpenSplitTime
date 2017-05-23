class RaceResultParser

  attr_reader :errors

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :json_response],
                           exclusive: [:event, :json_response], class: self.class)
    @event = args[:event]
    @json_response = args[:json_response]
    @errors = []
    validate_setup
  end

  def parsed_effort_data
    @parsed_time_data ||= response_data.map do |row|
      OpenStruct.new(bib_number: row[bib_index], name: row[name_index], gender: row[sex_index], age: row[age_index],
                     segment_times: time_points.zip(elapsed_times(row)).to_h)
    end
  end

  private

  attr_reader :event, :json_response

  def elapsed_times(row)
    times_in_seconds = segment_times_in_seconds(row)
    (0...times_in_seconds.size).map { |i| times_in_seconds[0..i].sum.round(2) }
  end

  def segment_times_in_seconds(row)
    segment_times_with_start(row).map { |time| TimeConversion.hms_to_seconds(time) }
  end

  def segment_times_with_start(row)
    row[split_index_range].unshift('0:00:00.00')
  end

  def time_points_count
    time_points.size
  end

  def time_points
    event.required_time_points
  end

  def response_data
    json_response['data'].values.first
  end

  def response_fields
    json_response['list']['Fields'].map.with_index { |field, i| {expression: field['Expression'], label: field['Label'], index: i + 1} }
  end

  def split_index_range
    @split_index_range ||= split_fields.first[:index]..split_fields.last[:index]
  end

  def split_fields
    response_fields.select { |field| field[:expression].starts_with?('Section') }
  end

  def bib_index
    @bib_index ||= response_fields.find { |field| field[:label] == 'Bib' }[:index]
  end

  def name_index
    @name_index ||= response_fields.find { |field| field[:label] == 'Name' }[:index]
  end

  def sex_index
    @sex_index ||= response_fields.find { |field| field[:label] == 'Sex' }[:index]
  end

  def age_index
    @age_index ||= response_fields.find { |field| field[:label] == 'Age' }[:index]
  end

  def validate_setup
    (errors << split_mismatch_error) if !event.laps_unlimited? && (split_fields.size != time_points_count - 1)
  end

  def split_mismatch_error
    {title: 'Split mismatch error',
     detail: {messages: ["#{event} expects #{time_points_count - 1} time points (excluding the start split) " +
                             "but the json response contemplates #{split_fields.size} time points."]}}
  end
end
