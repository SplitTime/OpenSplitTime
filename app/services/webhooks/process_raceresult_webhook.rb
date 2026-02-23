class ProcessRaceresultWebhook
  # The raw data is expected to be in the format: JSON_DATA;EVENT_GROUP_NAME
  def self.call(raw)
    new(raw).call
  end

  def initialize(raw)
    @raw = raw
  end

  def call
    parse_raw
    find_event_group
    process_data
    build_raw_time
    save_raw_time
    submit_raw_time

    raw_time
  end

  private

  attr_reader :raw
  attr_accessor :raw_attributes, :processed_attributes, :raw_time, :event_group_name, :event_group

  def parse_raw
    parts = raw.split(';')
    self.raw_attributes = JSON.parse(parts.first)
    self.event_group_name = parts.last
  end

  def find_event_group
    self.event_group = EventGroup.find_by!(name: event_group_name)
  end

  def process_data
    self.processed_attributes = {
      bib:          raw_attributes["Bib"],
      utc_time:     raw_attributes["UTCTime"],
      device_id:    raw_attributes.dig("Passing", "DeviceID"),
      timing_point: raw_attributes["TimingPoint"],
      id:           raw_attributes["ID"]
    }
  end

  def build_raw_time
    self.raw_time = RawTime.new(
      event_group: event_group,
      bib_number: processed[:bib],
      split_name: processed[:timing_point],
      entered_time: processed_attributes[:utc_time],
      bitkey: SubSplit::IN_BITKEY,
      source: "raceresult_webhook",
      created_by: nil
    )
  end

  def save_raw_time
    raw_time.save!
  end

  def submit_raw_time
    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: [raw_time])

    Interactors::SubmitRawTimeRows.perform!(
      raw_time_rows: raw_time_rows,
      event_group: event_group,
      force_submit: false,
      mark_as_reviewed: false,
      current_user_id: nil
    )
  end
end
