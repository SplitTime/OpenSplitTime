class AddAbsoluteTimeToSplitTimes < ActiveRecord::Migration[5.1]
  def up
    add_column :split_times, :absolute_time, :datetime

    sql = <<-SQL
      with time_subquery as 
         (select st.id, events.start_time + (efforts.start_offset * interval '1 second') + (st.time_from_start * interval '1 second') as computed_time
          from split_times st
          inner join efforts on efforts.id = st.effort_id
          inner join events on events.id = efforts.event_id
          order by st.id)
        
      update split_times
          set absolute_time = computed_time
          from time_subquery
          where split_times.id = time_subquery.id
    SQL

    ActiveRecord::Base.connection.execute(sql.squish)
  end

  def down
    remove_column :split_times, :absolute_time
  end
end
