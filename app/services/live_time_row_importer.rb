# frozen_string_literal: true

class LiveTimeRowImporter
  attr_reader :errors

  def self.import(args)
    importer = new(args)
    importer.import
    importer.returned_rows
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :time_rows],
                           exclusive: [:event, :time_rows, :force_submit],
                           class: self.class)
    @event = args[:event]
    @time_rows = args[:time_rows].values # keys are unneeded ids; values contains all needed data
    @force_submit = args[:force_submit]&.to_boolean
    @times_container ||= SegmentTimesContainer.new(calc_model: :stats)
    @unsaved_rows = Set.new
    @saved_split_times = {}
    @errors = []
    validate_time_rows
  end

  def import
    return if errors.present?
    time_rows.each do |time_row|
      effort_data = LiveEffortData.new(event: event,
                                       params: time_row,
                                       ordered_splits: ordered_splits,
                                       times_container: times_container)

      if effort_data.valid? && (effort_data.clean? || force_submit?)
        create_or_update_times(effort_data)
      else
        unsaved_rows << effort_data.response_row
      end
    end
    match_live_times
    notify_followers if event.permit_notifications?
  end

  def returned_rows
    {returned_rows: unsaved_rows}.camelize_keys
  end

  private

  EXTRACTABLE_ATTRIBUTES = %w(time_from_start data_status pacer remarks stopped_here live_time_id)

  attr_reader :event, :time_rows, :force_submit, :times_container
  attr_accessor :unsaved_rows, :saved_split_times

  # Returns true if all available times (in or out or both) are created/updated.
  # Returns false if any create/update is attempted but rejected

  def create_or_update_times(effort_data)
    effort = event.efforts.where(id: effort_data.effort.id).includes(split_times: :split).first
    person_id = effort_data.person_id || 0 # Id 0 is the dump for efforts with no person_id
    saved_split_times[person_id] ||= []

    temporary_split_times = effort_data.proposed_split_times.map do |proposed_split_time|
      new_or_updated_split_time(effort, proposed_split_time)
    end

    viable_split_times = temporary_split_times.compact.select(&:time_from_start)

    stopped_split_time = viable_split_times.select(&:stopped_here?).last
    if stopped_split_time
      stop_response = Interactors::SetEffortStop.perform(effort, split_time_id: stopped_split_time.id)
    end
    offset_response = Interactors::AdjustEffortOffset.perform(effort)
    status_response = Interactors::SetEffortStatus.perform(effort, times_container: times_container)
    combined_response = status_response.merge(offset_response).merge(stop_response)

    ActiveRecord::Base.transaction do
      row_success = combined_response.successful? && effort.save

      if row_success
        viable_split_times.each do |saved_split_time|
          unless saved_split_time.live_time_id
            live_time = effort_data.new_live_times[SubSplit.kind(saved_split_time.bitkey).downcase.to_sym]
            live_time.split_time = saved_split_time
            live_time.save if live_time.valid?
          end
          saved_split_times[person_id] << saved_split_time
        end
      end

      unless row_success
        error_message = combined_response.successful? ? effort.errors.full_messages : combined_response.message_with_error_report
        error_response = effort_data.response_row.merge(message: error_message)
        unsaved_rows << error_response
        raise ActiveRecord::Rollback
      end
    end
  end

  def new_or_updated_split_time(effort, proposed_split_time)
    existing_split_time = effort.split_times.find { |st| st.time_point == proposed_split_time.time_point }
    return nil unless existing_split_time || proposed_split_time.time_from_start
    split_time = existing_split_time || effort.split_times.new(time_point: proposed_split_time.time_point)
    split_time.assign_attributes(extracted_attributes(proposed_split_time))
    split_time
  end

  # Extract only those extractable attributes that are non-nil (false must be extracted)
  def extracted_attributes(split_time)
    EXTRACTABLE_ATTRIBUTES.map { |attribute| [attribute, split_time.send(attribute)] }.to_h
        .select { |_, value| !value.nil? }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def force_submit?
    @force_submit
  end

  def match_live_times
    split_times = saved_split_times.values.flatten.select(&:live_time_id)
    split_times.each do |split_time|
      live_time = LiveTime.find(split_time.live_time_id)
      live_time.update(split_time: split_time)
    end
  end

  def notify_followers
    saved_split_times.each do |person_id, split_times|
      NotifyFollowersJob.perform_later(person_id: person_id,
                                       split_time_ids: split_times.map(&:id),
                                       multi_lap: event.multiple_laps?) unless person_id.zero?
    end
  end

  def validate_time_rows
    split_ids = time_rows.map { |row| row[:split_id].presence }.compact.uniq
    effort_ids = time_rows.map { |row| row[:effort_id].presence }.compact.uniq
    live_time_ids = time_rows.flat_map { |row| [row[:live_time_id_in].presence, row[:live_time_id_out].presence] }
                        .compact.uniq
    begin
      Split.find(split_ids)
    rescue ActiveRecord::RecordNotFound
      errors << split_not_found_error
    end

    begin
      Effort.find(effort_ids)
    rescue ActiveRecord::RecordNotFound
      errors << effort_not_found_error
    end

    begin
      LiveTime.find(live_time_ids)
    rescue ActiveRecord::RecordNotFound
      errors << live_time_not_found_error
    end
  end

  def split_not_found_error
    {title: 'Split not found',
     detail: {messages: ['One or more split_ids submitted in timeRows was not found']}}
  end

  def effort_not_found_error
    {title: 'Effort not found',
     detail: {messages: ['One or more effort_ids submitted in timeRows was not found']}}
  end

  def live_time_not_found_error
    {title: 'LiveTime not found',
     detail: {messages: ['One or more live_time_ids submitted in timeRows was not found']}}
  end
end
