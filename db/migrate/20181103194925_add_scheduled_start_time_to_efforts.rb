class AddScheduledStartTimeToEfforts < ActiveRecord::Migration[5.1]
  def up
    add_column :efforts, :scheduled_start_time, :datetime

    query = <<-SQL
      with 
        start_split_times as
          (select effort_id, absolute_time
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = 1 and kind = 0
           order by split_times.id),

        main_subquery as
          (select efforts.id, case when sst.absolute_time is null then events.start_time else sst.absolute_time end as start_time
           from efforts
             inner join events on events.id = efforts.event_id
             left join start_split_times sst on sst.effort_id = efforts.id
           order by efforts.id)
         
      update efforts
          set scheduled_start_time = m.start_time
          from main_subquery m
          where efforts.id = m.id
    SQL

    ActiveRecord::Base.connection.execute(query.squish)
  end

  def down
    remove_column :efforts, :scheduled_start_time
  end
end
