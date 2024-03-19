# frozen_string_literal: true

module ProjectionAssessments
  class Runner
    include ::Interactors::Errors

    UPDATE_INTERVAL = 5

    # @param [::ProjectionAssessmentRun] assessment_run
    # @return [Integer]
    def self.perform!(assessment_run)
      new(assessment_run).perform!
    end

    def initialize(assessment_run)
      @assessment_run = assessment_run
      @current_effort = nil
      @errors = []
    end

    # @return [Integer]
    def perform!
      start_assessment_run
      run_assessments
      fail_and_report_errors! if errors.present?
      success_count
    end

    private

    attr_reader :assessment_run, :errors
    attr_accessor :current_assessment, :current_effort

    delegate :completed_lap, :completed_split_id, :completed_bitkey,
             :projected_lap, :projected_split_id, :projected_bitkey,
             :success_count, :event, to: :assessment_run
    delegate :efforts, to: :event

    def start_assessment_run
      assessment_run.start!
    end

    def run_assessments
      assessment_run.processing!

      efforts.each do |effort|
        self.current_effort = effort
        assess_effort
        save_assessment!
      end

      assessment_run.finished! if errors.empty?
    end

    def fail_and_report_errors!
      assessment_run.update(status: :failed, error_message: errors.to_json)
    end

    def assess_effort
      self.current_assessment = assessment_run.assessments.new(effort: current_effort)
      current_completed_split_time = current_effort.split_times.find_by(lap: completed_lap, split_id: completed_split_id, bitkey: completed_bitkey)
      return unless current_completed_split_time

      completed_absolute_time = current_completed_split_time.absolute_time
      current_projected_split_time = current_effort.split_times.find_by(lap: projected_lap, split_id: projected_split_id, bitkey: projected_bitkey)
      projected_absolute_time = current_projected_split_time&.absolute_time

      projection = Projection.execute_query(
        split_time: current_completed_split_time,
        starting_time_point: starting_time_point,
        subject_time_points: [TimePoint.new(projected_lap, projected_split_id, projected_bitkey)],
        ignore_times_beyond: completed_absolute_time,
      ).first

      current_assessment.assign_attributes(
        projected_early: completed_absolute_time + projection.low_seconds,
        projected_best: completed_absolute_time + projection.average_seconds,
        projected_late: completed_absolute_time + projection.high_seconds,
        actual: projected_absolute_time,
      )
    end

    def save_assessment!
      if current_assessment.save
        assessment_run.increment(:success_count)
      else
        assessment_run.increment(:failure_count)
        errors << current_assessment.errors.full_messages
      end

      assessment_run.set_elapsed_time!
    end

    def starting_time_point
      @starting_time_point ||= event.starting_time_point
    end
  end
end
