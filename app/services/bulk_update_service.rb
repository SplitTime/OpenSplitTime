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
end
