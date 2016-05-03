class BulkUpdateService

  def self.bulk_update_split_time_status(update_hash)
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

  def self.bulk_update_effort_status(update_hash)
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