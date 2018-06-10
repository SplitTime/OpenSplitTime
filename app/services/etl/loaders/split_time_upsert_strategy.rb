# frozen_string_literal: true

module ETL::Loaders
  class SplitTimeUpsertStrategy < BaseLoader

    def post_initialize(options)
      @parent_model = Effort
      @child_model = SplitTime
      @parent_key = [:event_id, :bib_number]
      @child_key = [:lap, :split_id, :sub_split_bitkey]
    end

    def custom_load
      proto_records.each do |proto_effort|
        effort = find_effort(proto_effort) || Effort.new(proto_effort.to_h)

        if effort.persisted?
          proto_effort.children.each { |proto_split_time| prepare_attributes(proto_split_time, effort) }
          effort.assign_attributes(proto_effort.parent_child_attributes)
          Interactors::SetEffortStop.perform(effort) if effort.split_times.select(&:stopped_here?).many?

          if effort.changed?
            if effort.save
              saved_records << effort
            else
              invalid_records << effort
            end
          else
            ignored_records << effort
          end
        else
          ignored_records << effort
        end
      end
    end

    private

    attr_reader :parent_model, :child_model, :parent_key, :child_key

    def find_effort(proto_record)
      attributes = proto_record.to_h
      unique_attributes = attributes.slice(*parent_key)
      Effort.where(unique_attributes).includes(:split_times).first
    end

    def prepare_attributes(proto_split_time, effort)
      time_point = TimePoint.new(proto_split_time[:lap], proto_split_time[:split_id], proto_split_time[:sub_split_bitkey])
      existing_split_time = effort.split_times.find { |st| st.time_point == time_point }

      proto_split_time[:id] = existing_split_time.id if existing_split_time&.id
      proto_split_time[:created_by] = current_user_id unless existing_split_time
      proto_split_time[:updated_by] = current_user_id
      proto_split_time[:_destroy] = true if proto_split_time.record_action == :destroy
    end
  end
end
