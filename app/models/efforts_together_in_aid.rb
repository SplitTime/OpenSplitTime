# frozen_string_literal: true

class EffortsTogetherInAid < ::ApplicationQuery
  attribute :effort_id, :integer
  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :together_effort_ids, :integer_array_from_string

  def self.sql(effort_id)
    <<~SQL.squish
        with effort_time_intervals as
          (select ist.effort_id, ist.lap, ist.split_id, ist.absolute_time as in_time, ost.absolute_time as out_time, events.event_group_id
          from split_times ist
            join split_times ost on ist.effort_id = ost.effort_id and ist.lap = ost.lap and ist.split_id = ost.split_id and ost.sub_split_bitkey = 64
            join efforts on efforts.id = ist.effort_id
            join events on efforts.event_id = events.id
          where ist.effort_id = #{effort_id} and ist.sub_split_bitkey = #{SubSplit::IN_BITKEY}),

        group_split_times as
          (select effort_id, lap, split_id, 
              case when sub_split_bitkey = #{SubSplit::IN_BITKEY} then absolute_time else null end as in_time,
              case when sub_split_bitkey = #{SubSplit::OUT_BITKEY} then absolute_time else null end as out_time
          from split_times
            join efforts on efforts.id = split_times.effort_id
            join events on efforts.event_id = events.id
          where events.event_group_id = (select event_group_id from effort_time_intervals limit 1)),
            
        group_time_intervals as
          (select effort_id, lap, split_id, max(in_time) as in_time, max(out_time) as out_time
           from group_split_times
           group by effort_id, lap, split_id)

        select eti.effort_id, eti.lap, eti.split_id, array_agg(gti.effort_id) as together_effort_ids
        from effort_time_intervals eti
            left join group_time_intervals gti using (lap, split_id)
        where ((gti.in_time between eti.in_time and eti.out_time)
           or (gti.out_time between eti.in_time and eti.out_time)
           or (gti.in_time < eti.in_time and gti.out_time > eti.out_time))
           and eti.effort_id != gti.effort_id
        group by eti.effort_id, eti.lap, eti.split_id
        order by eti.effort_id, eti.lap, eti.split_id;
    SQL
  end

  def lap_split_key
    ::LapSplitKey.new(lap, split_id)
  end
end
