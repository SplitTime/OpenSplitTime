module Interactors
  class StartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts:, start_time: nil, broadcast_rows: true)
      new(efforts: efforts, start_time: start_time, broadcast_rows: broadcast_rows).perform!
    end

    def initialize(efforts:, start_time: nil, broadcast_rows: true)
      raise ArgumentError, "start_efforts must include efforts" unless efforts

      @efforts = efforts.to_a
      @start_time = start_time
      @broadcast_rows = broadcast_rows
      @errors = []
      @saved_split_times = []
      @changed_effort_ids = []
      preload_events
      validate_setup
    end

    def perform!
      if errors.blank?
        SplitTime.transaction do
          # Touches and the two derived-data callbacks are deferred and run
          # in batch in update_derived_data; see SplitTime#defer_derived_data
          ActiveRecord::Base.no_touching do
            efforts.each(&method(:start_effort))
          end
          raise ActiveRecord::Rollback if errors.present?

          update_derived_data
        end
        if errors.blank?
          enqueue_event_notifications
          broadcast_effort_updates
        end
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :efforts, :start_time, :broadcast_rows, :errors, :saved_split_times, :changed_effort_ids

    def preload_events
      ActiveRecord::Associations::Preloader.new(records: efforts, associations: :event).call
    end

    def start_effort(effort)
      start_split_id = start_split_ids_by_event_id.fetch(effort.event_id)
      split_time = existing_start_split_times[effort.id]

      unless split_time && split_time.split_id == start_split_id
        split_time = SplitTime.new(
          effort_id: effort.id,
          lap: 1,
          split_id: start_split_id,
          bitkey: SubSplit::IN_BITKEY,
        )
      end

      split_time.absolute_time = effort_start_time(effort)
      split_time.defer_derived_data = true

      if split_time.save
        saved_split_times << split_time
        changed_effort_ids << effort.id if split_time.saved_changes.present?
      else
        errors << resource_error_object(split_time)
      end
    end

    def events
      @events ||= efforts.map(&:event).uniq
    end

    def start_split_ids_by_event_id
      @start_split_ids_by_event_id ||= events.to_h { |event| [event.id, event.start_split.id] }
    end

    def existing_start_split_times
      @existing_start_split_times ||= SplitTime.where(
        effort_id: efforts.map(&:id),
        lap: 1,
        split_id: start_split_ids_by_event_id.values.uniq,
        bitkey: SubSplit::IN_BITKEY,
      ).index_by(&:effort_id)
    end

    def update_derived_data
      return if changed_effort_ids.empty?

      ActiveRecord::Base.connection.execute(SplitTimeQuery.set_efforts_elapsed_times(changed_effort_ids))
      EffortSegment.set_for_efforts(changed_effort_ids)
      ::Results::SetEffortPerformanceData.perform!(changed_effort_ids)
      Effort.where(id: changed_effort_ids).touch_all
      Event.where(id: changed_event_ids).touch_all
    end

    def enqueue_event_notifications
      events.select { |event| changed_event_ids.include?(event.id) && event.topic_resource_key? }
            .each { |event| NotifyEventUpdateJob.perform_later(event.id) }
    end

    # The roster page relies on per-effort broadcasts to update its rows;
    # the suppressed touch chain would otherwise have fired these
    def broadcast_effort_updates
      return unless broadcast_rows

      changed_ids = changed_effort_ids.to_set
      efforts.select { |effort| changed_ids.include?(effort.id) }.each(&:broadcast_update)
    end

    def changed_event_ids
      @changed_event_ids ||= begin
        changed_ids = changed_effort_ids.to_set
        efforts.select { |effort| changed_ids.include?(effort.id) }.map(&:event_id).uniq
      end
    end

    def effort_start_time(effort)
      converted_start_time || effort.scheduled_start_time || effort.event_start_time
    end

    def converted_start_time
      if start_time.presence.nil?
        nil
      elsif start_time.acts_like?(:time)
        start_time
      elsif start_time.is_a?(String)
        start_time.in_time_zone(time_zone)
      end
    end

    def time_zone
      @time_zone ||= efforts.first&.home_time_zone
    end

    def response_message
      started_time = if converted_start_time
                       I18n.l(converted_start_time,
                              format: :datetime_input)
                     else
                       "the scheduled start #{pluralize(
                         saved_split_times.size, 'time'
                       )}"
                     end
      if errors.present?
        "No efforts were started"
      else
        "Started #{pluralize(saved_split_times.size,
                             'effort')} at #{started_time}"
      end
    end

    def validate_setup
      if efforts.empty?
        errors << efforts_not_provided_error
        return
      end

      errors << multiple_event_groups_error(event_group_ids) if event_group_ids.many?
      errors << invalid_start_time_error(start_time) if invalid_start_time?
      errors << invalid_start_time_error(start_time || "nil") unless converted_start_time ||
                                                                     efforts.all?(&:scheduled_start_time?) ||
                                                                     efforts.all?(&:event)
    end

    def event_group_ids
      @event_group_ids ||= events.map(&:event_group_id).uniq
    end

    def invalid_start_time?
      start_time.is_a?(String) && start_time.present? && start_time.in_time_zone(time_zone).nil?
    end
  end
end
