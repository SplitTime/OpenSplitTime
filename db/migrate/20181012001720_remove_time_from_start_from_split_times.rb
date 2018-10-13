class RemoveTimeFromStartFromSplitTimes < ActiveRecord::Migration[5.1]
  def up
    remove_column :split_times, :time_from_start
    remove_column :efforts, :start_offset
  end

  def down
    add_column :split_times, :time_from_start, :float
    add_column :efforts, :start_offset, :integer, default: 0

    offset_sql = <<-SQL
      with offset_subquery as 
         (select efforts.id, extract(epoch from st.absolute_time - events.start_time) as computed_offset
           from split_times st
           inner join efforts on efforts.id = st.effort_id
           inner join events on events.id = efforts.event_id
           inner join splits on splits.id = st.split_id
           where st.lap = 1 and splits.kind = 0
           order by st.id)
        
      update efforts
          set start_offset = computed_offset
          from offset_subquery
          where efforts.id = offset_subquery.id
    SQL

    tfs_sql = <<-SQL
      with start_split_times as
        (select split_times.id, effort_id, absolute_time
         from split_times
         inner join splits on splits.id = split_times.split_id
         where lap = 1 and kind = 0
         order by split_times.id),
         
      tfs_subquery as
        (select st.id, extract(epoch from st.absolute_time - (case when sst.absolute_time is null then events.start_time else sst.absolute_time end)) as computed_tfs
         from split_times st
         inner join efforts on efforts.id = st.effort_id
         inner join events on events.id = efforts.event_id
         left join start_split_times sst on sst.effort_id = st.effort_id
         order by st.id)

      update split_times
          set time_from_start = computed_tfs
          from tfs_subquery
          where split_times.id = tfs_subquery.id
    SQL

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute('LOCK efforts, split_times IN ACCESS EXCLUSIVE MODE')
      ActiveRecord::Base.connection.execute(offset_sql.squish)
      ActiveRecord::Base.connection.execute(tfs_sql.squish)
    end

    change_column_null :split_times, :time_from_start, false
    change_column_null :efforts, :start_offset, false
  end
end
