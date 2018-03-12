# frozen_string_literal: true

module Interactors
  class CreateSplitTimesFromLiveTimes
    include Interactors::Errors

    # TODO The parallel logic located in LiveTimeRowImporter#create_or_update_times should be centralized here.

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event, :live_times],
                             exclusive: [:event, :live_times],
                             class: self.class)
      @event = args[:event]
      @live_times = args[:live_times]
      @created_split_times = []
      @errors = []
      validate_setup
    end

    def perform!
      unless errors.present?
        creatable_split_times.each { |split_time| create_and_update_resources(split_time) }
        update_efforts_status
        send_notifications if event.permit_notifications?
      end
      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :event, :live_times, :created_split_times, :errors

    def create_and_update_resources(split_time)
      if split_time.save
        created_split_times << split_time
        live_time = live_times.find { |lt| lt.id == split_time.live_time_id }
        live_time.update(split_time: split_time) if live_time
      else
        errors << resource_error_object(split_time)
      end
    end

    def update_efforts_status
      updated_efforts = Effort.where(id: created_split_times.map(&:effort_id).uniq).includes(split_times: :split)
      Interactors::UpdateEffortsStatus.perform!(updated_efforts)
    end

    def send_notifications
      notify_split_times = SplitTime.where(id: created_split_times.map(&:id)).includes(:effort).where.not(efforts: {person_id: nil})
      indexed_split_times = notify_split_times.group_by { |st| st.effort.person_id }
      indexed_split_times.each do |person_id, split_times|
        NotifyFollowersJob.perform_later(person_id: person_id,
                                         split_time_ids: split_times.map(&:id),
                                         multi_lap: event.multiple_laps?) unless person_id.zero?
      end
    end

    def creatable_split_times
      creatable_effort_data_objects.flat_map(&:proposed_split_times).select(&:time_from_start)
    end

    def creatable_effort_data_objects
      effort_data_objects.select { |effort_data| effort_data.clean? && effort_data.valid? }
    end

    def effort_data_objects
      @effort_data_objects ||= LiveTimeRowConverter.new(event: event, live_times: live_times).effort_data_objects
    end

    def message
      "Created #{created_split_times.size} new split times. " + failure_message
    end

    def failure_message
      errors.present? ? "Failed to create #{errors.size} split times. " : ''
    end

    def validate_setup
      errors << live_time_mismatch_error unless live_times.all? { |lt| lt.event_id == event.id }
    end
  end
end
