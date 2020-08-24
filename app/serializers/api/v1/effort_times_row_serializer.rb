# frozen_string_literal: true

module Api
  module V1
    class EffortTimesRowSerializer < ::Api::V1::BaseSerializer
      set_type :effort_times_rows

      attributes *EffortTimesRow::EXPORT_ATTRIBUTES, :display_style, :stopped, :dropped, :finished
      attribute :elapsed_times, if: Proc.new { |row| row.show_elapsed_times? }
      attribute :absolute_times, if: Proc.new { |row| row.show_absolute_times? }
      attribute :segment_times, if: Proc.new { |row| row.show_segment_times? }
      attribute :pacer_flags, if: Proc.new { |row| row.show_pacer_flags? }
      attribute :stopped_here_flags, if: Proc.new { |row| row.show_stopped_here_flags? }
      attribute :time_data_statuses, if: Proc.new { |row| row.show_time_data_statuses? }
    end
  end
end
