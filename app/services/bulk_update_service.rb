class BulkUpdateService

  # Changed_records is a hash containing {id: {attribute: value, attribute: value, ...}}

  def self.update_attributes(model, changed_records)
    begin
      Upsert.batch(ActiveRecord::Base.connection, model) do |upsert|
        changed_records.each do |resource|
          upsert.row({id: resource.first}, resource.last, updated_at: Time.now)
        end
      end
      "Updated #{changed_records.size} #{model.to_s.humanize(capitalize: false)}"
    rescue Exception => e
      puts "SQL error in #{ __method__ }"
      ActiveRecord::Base.connection.execute 'ROLLBACK'

      raise e
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
    "Added start times for #{efforts.size} efforts."
  end
end