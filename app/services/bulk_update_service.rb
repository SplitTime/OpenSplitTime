class BulkUpdateService

  def self.bulk_update_split_time_status(split_times)
    SplitTime.import split_times
  end

  def self.bulk_update_effort_status(efforts)
    Effort.import efforts
  end

  # def self.bulk_update_split_time_status(update_hash)
  #   # return if update_hash.blank?
  #   # connection = PG.connect(dbname: self.database_name)
  #   # table_name = :split_times
  #   # begin
  #   # Upsert.batch(connection, table_name) do |upsert|
  #   #   update_hash.each do |k, v|
  #   #     upsert.row({id: k}, data_status: SplitTime.data_statuses[v], updated_at: Time.now)
  #   #   end
  #   # end
  #   # rescue Exception => e
  #   #   puts "SQL error in #{ __method__ }"
  #   #   ActiveRecord::Base.connection.execute 'ROLLBACK'
  #   #
  #   #   raise e
  #   # end
  # end
  #
  # def self.bulk_update_effort_status(update_hash)
  #   # return if update_hash.blank?
  #   # connection = PG.connect(dbname: self.database_name)
  #   # table_name = :efforts
  #   # Upsert.batch(connection, table_name) do |upsert|
  #   #   update_hash.each do |k, v|
  #   #     upsert.row({id: k}, data_status: SplitTime.data_statuses[v], updated_at: Time.now)
  #   #   end
  #   # end
  # end
  #
  # def self.database_name
  #   # case Rails.env
  #   #   when 'development'
  #   #     'ost-development'
  #   #   when 'test'
  #   #     'ost-test'
  #   #   when 'production'
  #   #     ENV['DATABASE_URL']
  #   #   else
  #   #     nil
  #   # end
  # end

end