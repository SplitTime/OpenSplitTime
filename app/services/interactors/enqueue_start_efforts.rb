module Interactors
  class EnqueueStartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    JOB_CLASS = "StartEffortsJob".freeze

    def self.perform!(event_group:, filter:, start_time:, current_user: nil)
      new(event_group: event_group, filter: filter, start_time: start_time, current_user: current_user).perform!
    end

    def initialize(event_group:, filter:, start_time:, current_user: nil)
      @event_group = event_group
      @filter = filter || {}
      @start_time = start_time
      @current_user = current_user
      @errors = []
    end

    def perform!
      if effort_ids.empty?
        errors << efforts_not_provided_error
        message = "No entrants were found to start."
      elsif duplicate_task?
        errors << duplicate_async_task_error(JOB_CLASS)
        message = "Entrants for this start time are already being started."
      else
        enqueue_job
        message = "Starting #{pluralize(effort_ids.size, 'entrant')}. This may take a minute for large events."
      end

      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :event_group, :filter, :start_time, :current_user, :errors

    def effort_ids
      @effort_ids ||= begin
        efforts = event_group.efforts.roster_subquery
        Effort.from(efforts, :efforts).where(filter).ids
      end
    end

    def duplicate_task?
      context_key.present? &&
        AsyncTask.active_for?(parent: event_group, job_class: JOB_CLASS, context_key: context_key)
    end

    def enqueue_job
      task = AsyncTask.create!(
        parent: event_group,
        user: current_user,
        job_class: JOB_CLASS,
        context_key: context_key,
        description: "Starting #{pluralize(effort_ids.size, 'entrant')}",
      )
      StartEffortsJob.perform_later(task, effort_ids: effort_ids, start_time: start_time,
                                          current_user: current_user)
    end

    def context_key
      return @context_key if defined?(@context_key)

      @context_key = begin
        assumed_start_time = filter[:assumed_start_time].presence
        assumed_start_time && Time.zone.parse(assumed_start_time.to_s)&.utc&.iso8601
      rescue ArgumentError
        nil
      end
    end
  end
end
