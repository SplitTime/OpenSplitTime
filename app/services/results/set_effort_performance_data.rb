module Results
  class SetEffortPerformanceData
    def self.perform!(effort_ids)
      new(effort_ids).perform!
    end

    def initialize(effort_ids)
      @effort_ids = Array.wrap(effort_ids)
    end

    def perform!
      return if effort_ids.empty?

      ::ActiveRecord::Base.connection.execute(query)
    end

    private

    attr_reader :effort_ids

    def ids
      effort_ids.map(&:to_i).join(",")
    end

    def query
      <<~SQL.squish
        with relevant_efforts as (select id, event_id from efforts where id in (#{ids})),

             starting_split_times as (
                 select st.effort_id, st.id, st.absolute_time
                 from relevant_efforts e
                          join split_times st on st.effort_id = e.id
                          join splits s on st.split_id = s.id
                 where st.lap = 1
                   and s.kind = 0
             ),

             last_split_times as (
                 select distinct on (e.id)
                        e.id as effort_id,
                        st.id,
                        st.lap,
                        st.sub_split_bitkey,
                        st.absolute_time,
                        s.distance_from_start,
                        s.kind,
                        case
                            when ev.laps_required = 0 then null
                            else ((s.kind = 1 and st.lap = ev.laps_required) or st.lap > ev.laps_required) end as fixed_lap_finish
                 from relevant_efforts e
                          join events ev on ev.id = e.event_id
                          left join split_times st on st.effort_id = e.id
                          left join splits s on st.split_id = s.id
                 order by e.id, st.lap desc, s.distance_from_start desc, st.sub_split_bitkey desc
             ),

             stopped_split_times as (
                 select distinct on (st.effort_id)
                        st.effort_id,
                        st.id
                 from split_times st
                          join splits s on st.split_id = s.id
                 where st.effort_id in (#{ids})
                   and st.stopped_here
                 order by st.effort_id, st.lap desc, s.distance_from_start desc, st.sub_split_bitkey desc
             )

        update efforts
        set stopped_split_time_id = stop_st.id,
            final_split_time_id   = last_st.id,
            completed_laps        = coalesce(case when last_st.kind = #{::Split.kinds[:finish]} then last_st.lap else last_st.lap - 1 end, 0),
            started               = last_st.id is not null,
            beyond_start          = coalesce(start_st.id <> last_st.id, last_st.id is not null),
            stopped               = stop_st.id is not null or last_st.fixed_lap_finish is true,
            dropped               = stop_st.id is not null and last_st.fixed_lap_finish is false,
            finished              = coalesce(last_st.fixed_lap_finish, stop_st.id is not null),
            overall_performance   = case
                                        when last_st.id is not null then
                                                            (stop_st.id is null or last_st.fixed_lap_finish is not false)::int::bit(1) ||
                                                            last_st.lap::bit(14) ||
                                                            last_st.distance_from_start::bit(30) ||
                                                            last_st.sub_split_bitkey::bit(7) ||
                                                            coalesce(~(extract(epoch from (last_st.absolute_time - start_st.absolute_time)) * 1000)::bigint, 0)::bigint::bit(44)
                                        else 0::bit(96) end
        from relevant_efforts ef
                 left join starting_split_times start_st on start_st.effort_id = ef.id
                 left join last_split_times last_st on last_st.effort_id = ef.id
                 left join stopped_split_times stop_st on stop_st.effort_id = ef.id
        where efforts.id = ef.id
      SQL
    end
  end
end
