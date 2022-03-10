# frozen_string_literal: true

module Results
  class SetEffortPerformanceData
    def self.perform!(effort_id)
      new(effort_id).perform!
    end

    def initialize(effort_id)
      @effort_id = effort_id
    end

    def perform!
      ::ActiveRecord::Base.connection.execute(query)
    end

    private

    attr_reader :effort_id

    def query
      <<~SQL.squish
        with relevant_effort as (select * from efforts where id = #{effort_id}),

             starting_split_time as (
                 select st.id, st.absolute_time
                 from relevant_effort e
                          left join split_times st on st.effort_id = e.id
                          left join splits s on st.split_id = s.id
                 where st.lap = 1
                   and s.kind = 0
             ),

             last_split_time as (
                 select st.id,
                        st.lap,
                        st.sub_split_bitkey,
                        st.absolute_time,
                        s.distance_from_start,
                        case
                            when ev.laps_required = 0 then null
                            else ((s.kind = 1 and st.lap = ev.laps_required) or st.lap > ev.laps_required) end as fixed_lap_finish
                 from relevant_effort e
                          join events ev on ev.id = e.event_id
                          left join split_times st on st.effort_id = e.id
                          left join splits s on st.split_id = s.id
                 order by st.lap desc, s.distance_from_start desc, st.sub_split_bitkey desc
                 limit 1
             ),

             stopped_split_time as (
                 select st.id
                 from relevant_effort e
                          left join split_times st on st.effort_id = e.id
                          left join splits s on st.split_id = s.id
                 where st.stopped_here
                 order by st.lap desc, s.distance_from_start desc, st.sub_split_bitkey desc
                 limit 1
             )

        update efforts
        set stopped_split_time_id = stop_st.id,
            final_split_time_id   = last_st.id,
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
        from relevant_effort ef
                 left join starting_split_time start_st on true
                 left join last_split_time last_st on true
                 left join stopped_split_time stop_st on true
        where efforts.id = ef.id
      SQL
    end
  end
end
