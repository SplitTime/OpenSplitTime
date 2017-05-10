class BulkUpdateService

  # Changed_records is a hash containing {id: {attribute: value, attribute: value, ...}}

  def self.update_attributes(model, changed_records)
    if Rails.env.test? # Rspec doesn't play well with upsert
      klass = model.to_s.classify.constantize
      changed_records.each do |changed_record|
        subject_record = klass.find(changed_record.first)
        subject_record.update(changed_record.last)
      end
    else
      begin
        Upsert.batch(ActiveRecord::Base.connection, model) do |upsert|
          changed_records.each do |changed_record|
            upsert.row({id: changed_record.first}, changed_record.last, updated_at: Time.now)
          end
        end
        "Updated #{changed_records.size} #{model.to_s.humanize(capitalize: false)}"
      rescue Exception => e
        puts "SQL error in #{ __method__ }"
        ActiveRecord::Base.connection.execute 'ROLLBACK'

        raise e
      end
    end
  end

  def self.start_ready_efforts(event, current_user_id)
    efforts = event.efforts.ready_to_start
    start_efforts(efforts, current_user_id)
  end

  def self.start_efforts(efforts, current_user_id)
    start_split_id = efforts.first.event.start_split.id
    errors = []
    SplitTime.transaction do
      efforts.each do |effort|
        split_time = SplitTime.new(effort_id: effort.id,
                                   time_point: TimePoint.new(1, start_split_id, SubSplit::IN_BITKEY),
                                   time_from_start: 0,
                                   created_by: current_user_id,
                                   updated_by: current_user_id)
        errors << [split_time.attributes, split_time.errors.full_messages] unless split_time.save
      end
      raise ActiveRecord::Rollback if errors.present?
    end
    errors.present? ? errors : "Added start times for #{efforts.size} efforts."
  end
end
