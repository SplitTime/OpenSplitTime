# frozen_string_literal: true

module ETL
  module Transformers
    class RaceResultSplitTimesStrategy < BaseTransformer
      def initialize(parsed_structs, options)
        @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
        @options = options
        @errors = []
        add_section_times! if time_keys.size.zero?
        validate_setup
      end

      def transform
        return if errors.present?

        proto_records.each do |proto_record|
          transform_time_data!(proto_record)
          proto_record.record_type = :effort
          proto_record.map_keys!({name: :full_name, sex: :gender, bib: :bib_number})
          proto_record.normalize_gender!
          proto_record.split_field!(:full_name, :first_name, :last_name)
          proto_record.slice_permitted!
          proto_record.merge_attributes!(global_attributes)
        end

        # RaceResult sometimes includes no-name runners ("N.n.") who have no gender.
        # We need to filter these out or they will cause the import to fail.
        proto_records.select { |record| record[:gender].present? }
      end

      private

      attr_reader :proto_records

      def add_section_times!
        proto_records.each do |proto_record|
          proto_record.map_keys!(chip_time: :time)
          proto_record[:section1_split] = ((proto_record[:time] == 'DNS') ? '' : proto_record[:time])
        end
        @time_keys = ['section1_split']
      end

      def transform_time_data!(proto_record)
        relocate_status_indicators!(proto_record)
        extract_times!(proto_record)
        transform_times!(proto_record)
        add_empty_times!(proto_record) if finish_times_only?
        proto_record.create_split_time_children!(time_points, preserve_nils: preserve_nils?, time_attribute: :absolute_time)
        mark_for_destruction!(proto_record)
        set_stop!(proto_record)
      end

      def relocate_status_indicators!(proto_record)
        unless proto_record[:time] =~ TimeConversion::HMS_FORMAT
          proto_record[:status_indicator] = proto_record[:time]
          proto_record[:time] = nil
        end
        unless proto_record[:section1_split] =~ TimeConversion::HMS_FORMAT
          proto_record[:status_indicator] ||= proto_record[:section1_split]
          proto_record[:section1_split] = proto_record[:status_indicator].in?(%w(DNF DSQ)) ? '00:00' : nil
        end
      end

      def extract_times!(proto_record)
        proto_record[:segment_times] = time_keys.map { |key| proto_record.delete_field(key) }
      end

      def transform_times!(proto_record)
        segment_seconds = proto_record[:segment_times].map { |hms_time| TimeConversion.hms_to_seconds(hms_time) }
        start_seconds = segment_seconds.any?(&:present?) ? 0.0 : nil
        finish_time = TimeConversion.hms_to_seconds(proto_record[:time])
        finish_seconds = finish_time == 0 ? nil : finish_time
        start_calcs = calcs_from_start(segment_seconds, start_seconds)
        finish_calcs = calcs_from_finish(segment_seconds, finish_seconds)
        proto_record[:times_from_start] = start_calcs.zip(finish_calcs).map { |pair| pair.compact.first }
        proto_record[:absolute_times] = proto_record[:times_from_start].map { |tfs| event.scheduled_start_time + tfs if tfs.present? }
      end

      def add_empty_times!(proto_record)
        return if time_points.size == proto_record[:absolute_times].size

        empty_times_needed = time_points.size - proto_record[:absolute_times].size
        empty_times = Array.new(empty_times_needed)
        proto_record[:absolute_times].insert(1, *empty_times)
      end

      def calcs_from_start(segment_seconds, start_seconds)
        calcs = segment_seconds.each_index.map do |i|
          left_partial_array = segment_seconds[0..i]
          (start_seconds + left_partial_array.sum).round(2) if start_seconds && left_partial_array.all?(&:present?)
        end
        calcs[-1] = nil
        calcs.unshift(start_seconds)
      end

      def calcs_from_finish(segment_seconds, finish_seconds)
        calcs = segment_seconds.each_index.map do |i|
          right_partial_array = segment_seconds[i..-1]
          (finish_seconds - right_partial_array.sum).round(2) if finish_seconds && right_partial_array.all?(&:present?)
        end
        calcs[0] = nil
        calcs.push(finish_seconds)
      end

      def mark_for_destruction!(proto_record)
        proto_record.children.each do |child_record|
          child_record.record_action = :destroy if child_record[:absolute_time].blank?
        end
      end

      def set_stop!(proto_record)
        stop_indicators = %w(DNF DSQ)
        if stop_indicators.include?(proto_record[:status_indicator])
          stopped_child_record = proto_record.children.reverse.find { |pr| pr[:absolute_time].present? }
          (stopped_child_record[:stopped_here] = true) if stopped_child_record
        end
      end

      # Because of the way they are built, keys for all structs are identical,
      # so use the first as a template for all.
      def time_keys
        @time_keys ||= proto_records.first.to_h.keys
                                    .select { |key| key.to_s.start_with?('section') }
                                    .sort_by { |key| key[/\d+/].to_i }
      end

      def global_attributes
        {event_id: event.id}
      end

      def time_points
        @time_points ||= event.required_time_points
      end

      def preserve_nils?
        options[:delete_blank_times]
      end

      def finish_times_only?
        time_keys.size == 1
      end

      def validate_setup
        errors << missing_event_error and return unless event.present?

        if !event.laps_unlimited? && !finish_times_only? && (time_keys.size + 1 != time_points.size)
          errors << split_mismatch_error(event, time_points.size, time_keys.size + 1)
        end
      end
    end
  end
end
