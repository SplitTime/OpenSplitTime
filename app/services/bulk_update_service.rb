class BulkUpdateService

  def self.bulk_update_split_time_status(update_hash)
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |k, v|
        split_time = SplitTime.find(k)
        split_time.update(data_status: SplitTime.data_statuses[v], updated_at: Time.now)
      end
    else
      begin
        return if update_hash.blank?
        connection = ActiveRecord::Base.connection
        table_name = :split_times
        begin
          Upsert.batch(connection, table_name) do |upsert|
            update_hash.each do |k, v|
              upsert.row({id: k}, data_status: SplitTime.data_statuses[v], updated_at: Time.now)
            end
          end
        rescue Exception => e
          puts "SQL error in #{ __method__ }"
          ActiveRecord::Base.connection.execute 'ROLLBACK'

          raise e
        end
      end
    end
  end

  def self.bulk_update_effort_status(update_hash)
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |k, v|
        effort = Effort.find(k)
        effort.update(data_status: Effort.data_statuses[v], updated_at: Time.now)
      end
    else
      begin
        return if update_hash.blank?
        connection = ActiveRecord::Base.connection
        table_name = :efforts
        Upsert.batch(connection, table_name) do |upsert|
          update_hash.each do |k, v|
            upsert.row({id: k}, data_status: SplitTime.data_statuses[v], updated_at: Time.now)
          end
        end
      rescue Exception => e
        puts "SQL error in #{ __method__ }"
        ActiveRecord::Base.connection.execute 'ROLLBACK'

        raise e
      end
    end
  end

end