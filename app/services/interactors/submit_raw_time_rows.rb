# frozen_string_literal: true

module Interactors
  class SubmitRawTimeRows
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:raw_time_rows, :event_group, :params, :current_user_id],
                             exclusive: [:raw_time_rows, :event_group, :params, :current_user_id],
                             class: self.class)
      @raw_time_rows = args[:raw_time_rows]
      @event_group = args[:event_group]
      @params = args[:params]
      @current_user_id = args[:current_user_id]
      @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
      @problem_rows = []
      @upserted_split_times = []
      @errors = []
    end

    def perform!
      raw_time_rows.each do |bare_rtr|
        ActiveRecord::Base.transaction do
          find_effort(bare_rtr)
          rtr = enriched_raw_time_row(bare_rtr)
          save_raw_times(rtr) unless rtr.errors.present?
          upsert_split_times(rtr) unless rtr.errors.present?
          if rtr.errors.present?
            rtr << problem_rows
            raise ActiveRecord::Rollback
          end
        end
      end
      send_notifications if event_group.permit_notifications?

      Interactors::Response.new(errors, '', resources).merge(upsert_response)
    end

    private

    attr_reader :raw_time_rows, :event_group, :params, :current_user_id, :times_container, :problem_rows,
                :upserted_split_times, :errors

    def find_effort(rtr)
      raw_time = rtr.raw_times.first
      return unless raw_time
      raw_bib = raw_time.bib_number
      integer_bib = raw_bib =~ /\D/ ? nil : raw_bib.to_i
      rtr.effort = indexed_efforts[integer_bib]
    end

    def enriched_raw_time_row(bare_rtr)
      if bare_rtr.effort
        enriched_rtr = EnrichRawTimeRow.perform(event_group: event_group, raw_time_row: bare_rtr, times_container: times_container)
        enriched_rtr.errors << 'row is not clean' unless (enriched_rtr.clean? || force?)
        enriched_rtr
      else
        VerifyRawTimeRow.perform(bare_rtr.dup) # Adds relevant errors to the raw_time_row
      end
    end

    def save_raw_times(rtr)
      rtr.raw_times.select! { |raw_time| raw_time.entered_time.present? } # Throw away empty raw_times
      rtr.raw_times.each do |raw_time|
        raw_time.assign_attributes(event_group_id: event_group.id, pulled_by: current_user_id, pulled_at: Time.current)
        raw_time.source ||= "Live Entry (#{current_user_id})"
        unless raw_time.save
          rtr.errors << resource_error_object(raw_time)
        end
      end
    end

    def upsert_split_times(rtr)
      upsert_response = Interactors::UpsertSplitTimesFromRawTimeRow.perform!(event_group: event_group, raw_time_row: rtr)
      upsert_response.resources[:upserted_split_times].each { |st| upserted_split_times << st }
    end

    def send_notifications
      indexed_split_times = upserted_split_times.group_by { |st| st.effort.person_id }
      indexed_split_times.each do |person_id, split_times|
        NotifyFollowersJob.perform_later(person_id: person_id, split_time_ids: split_times.map(&:id)) if person_id
      end
    end

    def indexed_efforts
      @indexed_efforts ||= Effort.where(event: event_group.events, bib_number: bib_numbers)
                               .includes(event: :splits, split_times: :split).index_by(&:bib_number)
    end

    def bib_numbers
      # Remove bib numbers that contain non-digits, then convert to integers
      raw_time_rows.flat_map { |rtr| rtr.raw_times.bib_number }.uniq.reject { |raw_bib| raw_bib =~ /\D/ }.map(&:to_i)
    end

    def resources
      {problem_rows: problem_rows, upserted_split_times: upserted_split_times}
    end

    def force?
      params[:force_submit]&.to_boolean
    end
  end
end
