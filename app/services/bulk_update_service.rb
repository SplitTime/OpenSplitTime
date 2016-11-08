class BulkUpdateService

  def self.bulk_update_split_time_status(update_hash)
    return if update_hash.blank?
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |split_time_id, status|
        split_time = SplitTime.find(split_time_id)
        split_time.update(data_status: SplitTime.data_statuses[status], updated_at: Time.now)
      end
    else
      begin
        connection = ActiveRecord::Base.connection
        table_name = :split_times
        begin
          Upsert.batch(connection, table_name) do |upsert|
            update_hash.each do |split_time_id, status|
              upsert.row({id: split_time_id}, data_status: SplitTime.data_statuses[status], updated_at: Time.now)
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
    return if update_hash.blank?
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |effort_id, status|
        effort = Effort.find(effort_id)
        effort.update(data_status: Effort.data_statuses[status], updated_at: Time.now)
      end
    else
      begin
        connection = ActiveRecord::Base.connection
        table_name = :efforts
        Upsert.batch(connection, table_name) do |upsert|
          update_hash.each do |effort_id, status|
            upsert.row({id: effort_id}, data_status: SplitTime.data_statuses[status], updated_at: Time.now)
          end
        end
      rescue Exception => e
        puts "SQL error in #{ __method__ }"
        ActiveRecord::Base.connection.execute 'ROLLBACK'

        raise e
      end
    end
  end

  def self.bulk_update_dropped(update_hash)
    return if update_hash.blank?
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |effort_id, dropped_split_id|
        effort = Effort.find(effort_id)
        effort.update(dropped_split_id: dropped_split_id, updated_at: Time.now)
      end
    else
      begin
        connection = ActiveRecord::Base.connection
        table_name = :efforts
        Upsert.batch(connection, table_name) do |upsert|
          update_hash.each do |effort_id, dropped_split_id|
            upsert.row({id: effort_id}, dropped_split_id: dropped_split_id, updated_at: Time.now)
          end
        end
      rescue Exception => e
        puts "SQL error in #{ __method__ }"
        ActiveRecord::Base.connection.execute 'ROLLBACK'

        raise e
      end
    end
  end

  def self.bulk_update_start_offset(update_hash)
    return if update_hash.blank?
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |effort_id, start_offset|
        effort = Effort.find(effort_id)
        effort.update(start_offset: start_offset, updated_at: Time.now)
        split_time = effort.start_split_time
        split_time.update(time_from_start: 0)
      end
    else
      begin
        split_time_ids = SplitTime.includes(:split).where(effort_id: update_hash.keys, splits: {kind: 0}).pluck(:id)
        connection = ActiveRecord::Base.connection
        table_name = :efforts
        Upsert.batch(connection, table_name) do |upsert|
          update_hash.each do |effort_id, start_offset|
            upsert.row({id: effort_id}, start_offset: start_offset, updated_at: Time.now)
          end
        end
        table_name = :split_times
        Upsert.batch(connection, table_name) do |upsert|
          split_time_ids.each do |split_time_id|
            upsert.row({id: split_time_id}, time_from_start: 0, updated_at: Time.now)
          end
        end
      rescue Exception => e
        puts "SQL error in #{ __method__ }"
        ActiveRecord::Base.connection.execute 'ROLLBACK'

        raise e
      end
    end
  end

  def self.start_all_efforts(event, current_user_id)
    start_efforts(event.efforts, current_user_id)
  end

  def self.start_efforts(efforts, current_user_id)
    start_split_id = efforts.first.event.start_split.id
    SplitTime.bulk_insert(:effort_id, :split_id, :sub_split_bitkey, :time_from_start, :created_at, :updated_at, :created_by, :updated_by) do |worker|
      efforts.each do |effort|
        worker.add(effort_id: effort.id,
                   split_id: start_split_id,
                   sub_split_bitkey: SubSplit::IN_BITKEY,
                   time_from_start: 0,
                   created_by: current_user_id,
                   updated_by: current_user_id)
      end
    end
    # TODO determine if split_times were actually added before returning this report
    "Added start times for #{efforts.count} efforts."
  end

  def self.set_dropped_split_ids(update_hash)
    return if update_hash.blank?
    if Rails.env.test? # Rspec doesn't seem to play well with upsert
      update_hash.each do |effort_id, dropped_split_id|
        effort = Effort.find(effort_id)
        effort.update(dropped_split_id: dropped_split_id, updated_at: Time.now)
      end
    else
      begin
        connection = ActiveRecord::Base.connection
        table_name = :efforts
        Upsert.batch(connection, table_name) do |upsert|
          update_hash.each do |effort_id, dropped_split_id|
            upsert.row({id: effort_id}, dropped_split_id: dropped_split_id, updated_at: Time.now)
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