module Api
  module V1
    class EffortTimesRowSerializer < ::Api::V1::BaseSerializer
      set_type :effort_times_rows

      attributes(*EffortTimesRow::EXPORT_ATTRIBUTES, :display_style, :stopped, :dropped, :finished)
      attribute :absolute_times, if: proc { |row| row.show_absolute_times? }

      attribute :elapsed_times, if: proc { |row|
        row.show_elapsed_times?
      } do |object|
        object.elapsed_times.map { |e| e.map { |time| time&.to_f } }
      end

      attribute :segment_times, if: proc { |row|
        row.show_segment_times?
      } do |object|
        object.segment_times.map { |e| e.map { |time| time&.to_f } }
      end

      attribute :pacer_flags, if: proc { |row| row.show_pacer_flags? }
      attribute :stopped_here_flags, if: proc { |row| row.show_stopped_here_flags? }
      attribute :time_data_statuses, if: proc { |row| row.show_time_data_statuses? }
    end
  end
end
