# frozen_string_literal: true

module Interactors
  class SubmitRawTimeRows
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event_group, :raw_time_rows, :params, :current_user_id],
                             exclusive: [:event_group, :raw_time_rows, :params, :current_user_id],
                             class: self.class)
      @event_group = args[:event_group]
      @params = args[:params]
      @current_user_id = args[:current_user_id]
      @unconsidered_rows, @problem_rows = args[:raw_time_rows].partition(&partition_method)
      @saved_rows = []
      @errors = []
    end

    def perform!
      process_raw_time_rows
      upsert_response = Interactors::UpsertSplitTimesFromRawTimes.perform!(event_group: event_group, raw_times: saved_raw_times)
      Interactors::Response.new(errors, message, resources).merge(upsert_response)
    end

    private

    attr_reader :event_group, :params, :current_user_id, :errors, :unconsidered_rows, :problem_rows, :saved_rows, :resources

    def process_raw_time_rows
      unconsidered_rows.each do |rtr|
        ActiveRecord::Base.transaction do
          rtr_errors = []

          rtr.raw_times.select! { |raw_time| raw_time.entered_time.present? } # Throw away empty raw_times
          rtr.raw_times.each do |raw_time|
            raw_time.assign_attributes(event_group_id: event_group.id, pulled_by: current_user_id, pulled_at: Time.current)
            raw_time.source ||= "Live Entry (#{current_user_id})"
            unless raw_time.save
              rtr_errors << resource_error_object(raw_time)
            end
          end

          if rtr_errors.present?
            rtr.errors ||= []
            rtr.errors << rtr_errors
            problem_rows << rtr
            raise ActiveRecord::Rollback
          else
            saved_rows << rtr
          end

        end
      end
    end

    def message
      nil
    end

    def resources
      {problem_rows: problem_rows}
    end

    def saved_raw_times
      saved_rows.flat_map(&:raw_times)
    end

    def partition_method
      force? ? :itself : :clean?
    end

    def force?
      params[:force_submit]&.to_boolean
    end
  end
end
