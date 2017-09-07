class SplitTimeValidator < ActiveModel::Validator
  def validate(record)
    record_event_course = record.event&.course
    if record_event_course && record.split_times.eager_load(split: :course).any? { |st| st.split.course != record_event_course }
      record.errors.add(:event, "course doesn't reconcile with split_times => split => course")
    end
  end
end
