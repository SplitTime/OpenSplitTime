# frozen_string_literal: true

# Each raw_time submitted to this class should already have a new_split_time attached to it,
# for example, as a result of the EnrichRawTimeRow service.
#
# The new_split_times will overwrite any existing split_times from the same effort on the same time_point.

module Interactors
  class UpsertSplitTimesFromRawTimes
    include Interactors::Errors
    ASSIGNABLE_ATTRIBUTES = %w[effort_id lap split_id sub_split_bitkey time_from_start stopped_here pacer remarks]

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event_group, :raw_times],
                             exclusive: [:event_group, :raw_times],
                             class: self.class)
      @event_group = args[:event_group]
      @raw_times = args[:raw_times]
      @created_split_times = []
      @errors = []
      validate_setup
    end

    def perform!
      unless errors.present?
        raw_times.each { |raw_time| create_and_update_resources(raw_time) }
        update_efforts_status
        send_notifications if event_group.permit_notifications?
      end
      Interactors::Response.new(errors, message, {})
    end

    private

    attr_reader :event_group, :raw_times, :created_split_times, :errors
    delegate :events, to: :event_group

    def create_and_update_resources(raw_time)
      new_split_time = raw_time.new_split_time
      effort = indexed_efforts[new_split_time.effort_id]
      upsert_split_time = effort.split_times.find { |st| st.time_point == new_split_time.time_point } || SplitTime.new
      upsert_split_time.assign_attributes(new_split_time.attributes.slice(*ASSIGNABLE_ATTRIBUTES))

      ActiveRecord::Base.transaction do
        if upsert_split_time.save
          if raw_time.update(split_time_id: upsert_split_time.id)
            created_split_times << upsert_split_time
          else
            errors << resource_error_object(raw_time)
          end
        else
          errors << resource_error_object(upsert_split_time)
        end
        raise ActiveRecord::Rollback if errors.present?
      end
    end

    def update_efforts_status
      updated_efforts = created_split_times.map { |st| indexed_efforts[st.effort_id] }.uniq
      Interactors::UpdateEffortsStatus.perform!(updated_efforts)
    end

    def send_notifications
      notify_split_times = SplitTime.where(id: created_split_times.map(&:id)).includes(:effort).where.not(efforts: {person_id: nil})
      indexed_split_times = notify_split_times.group_by { |st| st.effort.person_id }
      indexed_split_times.each do |person_id, split_times|
        NotifyFollowersJob.perform_later(person_id: person_id, split_time_ids: split_times.map(&:id)) unless person_id.zero?
      end
    end

    def indexed_efforts
      Effort.where(id: raw_times.map { |rt| rt.new_split_time.effort_id }.uniq).includes(split_times: :split).index_by(&:id)
    end

    def message
      "Created #{created_split_times.size} new split times. " + failure_message
    end

    def failure_message
      errors.present? ? "Failed to create #{errors.size} split times. " : ''
    end

    def validate_setup
      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
      errors << missing_new_split_time_error(raw_times.reject(&:new_split_time).first) unless raw_times.all?(&:new_split_time)
    end
  end
end
