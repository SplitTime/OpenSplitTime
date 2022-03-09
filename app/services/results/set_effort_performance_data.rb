# frozen_string_literal: true

module Results
  class SetEffortPerformanceData
    def self.perform!(*effort_ids)
      new(*effort_ids).perform!
    end

    def initialize(*effort_ids)
      @effort_ids = effort_ids
    end

    def perform!
      ::ActiveRecord::Base.connection.execute(query)
    end

    private

    attr_reader :effort_ids

    def query
      effort_ids_string = effort_ids.join(",")

      <<~SQL.squish
        with scoped_efforts as (
            select id, event_id
            from efforts
            where efforts.id in (#{effort_ids_string})
        ),

             course_subquery as (
                 select courses.id                 as course_id,
                        splits.distance_from_start as course_distance
                 from courses
                          join splits on splits.course_id = courses.id
                          join events on events.course_id = courses.id
                 where splits.kind = 1
                   and events.id in (select distinct on (event_id) event_id from scoped_efforts)
             ),

             start_times as (
                 select effort_id, absolute_time
                 from split_times
                          join splits on splits.id = split_times.split_id
                 where split_times.effort_id in (select id from scoped_efforts)
                   and split_times.lap = 1
                   and splits.kind = 0
                 order by split_times.effort_id
             ),

             beyond_start_efforts as (
                 select distinct on (effort_id) effort_id
                 from split_times
                          join splits on splits.id = split_times.split_id
                 where split_times.effort_id in (select id from scoped_efforts)
                   and (kind != 0 or lap != 1)
                 order by effort_id
             ),

             stopped_split_times as (
                 select split_times.effort_id,
                        split_times.id as stopped_split_time_id
                 from split_times
                 where split_times.effort_id in (select id from scoped_efforts)
                   and split_times.stopped_here
             ),

             final_split_times as (
                 select distinct on (split_times.effort_id) split_times.effort_id,
                                                            split_times.id               as final_split_time_id,
                                                            splits.distance_from_start   as final_lap_distance,
                                                            split_times.lap              as final_lap,
                                                            split_times.split_id         as final_split_id,
                                                            split_times.sub_split_bitkey as final_bitkey,
                                                            split_times.absolute_time    as final_absolute_time,
                                                            split_times.elapsed_seconds  as final_elapsed_seconds,
                                                            splits.kind = 1              as final_lap_complete
                 from split_times
                          join splits on splits.id = split_times.split_id
                 where split_times.effort_id in (select id from scoped_efforts)
                 order by split_times.effort_id,
                          final_lap desc,
                          final_lap_distance desc,
                          final_bitkey desc
             ),

             base_subquery as (
                 select scoped_efforts.id                                                  as effort_id,
                        events.laps_required,
                        stopped_split_time_id,
                        course_distance,
                        final_split_time_id,
                        final_lap,
                        final_lap_distance,
                        final_bitkey,
                        final_elapsed_seconds,
                        (final_lap - 1) * course_distance + final_lap_distance             as final_distance,
                        final_lap is not null                                              as started,
                        bse.effort_id is not null                                          as beyond_start,
                        case when final_lap is null then 0
                             when final_lap_complete then final_lap 
                             else final_lap - 1 
                        end as laps_finished
                 from scoped_efforts
                          left join events on events.id = scoped_efforts.event_id
                          left join course_subquery on events.course_id = course_subquery.course_id
                          left join start_times on start_times.effort_id = scoped_efforts.id
                          left join beyond_start_efforts bse on bse.effort_id = scoped_efforts.id
                          left join stopped_split_times on stopped_split_times.effort_id = scoped_efforts.id
                          left join final_split_times on final_split_times.effort_id = scoped_efforts.id
                 order by effort_id
             ),

             base_with_finished as (
                 select *,
                        case
                            when laps_required = 0
                                then stopped_split_time_id is not null
                            else
                                laps_finished >= laps_required
                            end
                            as finished
                 from base_subquery
             ),

             base_with_status as (
                 select *,
                        (finished or stopped_split_time_id is not null)                  as stopped,
                        (finished or stopped_split_time_id is not null) and not finished as dropped
                 from base_with_finished
             ),

             update_data as (
                 select effort_id,
                        stopped_split_time_id,
                        final_split_time_id,
                        started,
                        beyond_start,
                        stopped,
                        dropped,
                        finished,
                        case
                            when started
                                then (not dropped)::int::bit(1) || final_lap::bit(14) || final_distance::bit(30) ||
                                     final_bitkey::bit(7) || ~(coalesce(final_elapsed_seconds, 0) * 1000)::int::bit(44)
                            else
                                0::bit(96)
                            end
                            as overall_performance

                 from base_with_status
                 order by effort_id
             )

        update efforts
        set stopped_split_time_id = update_data.stopped_split_time_id,
            final_split_time_id   = update_data.final_split_time_id,
            started               = update_data.started,
            beyond_start          = update_data.beyond_start,
            stopped               = update_data.stopped,
            dropped               = update_data.dropped,
            finished              = update_data.finished,
            overall_performance   = update_data.overall_performance
        from update_data
        where efforts.id = update_data.effort_id;
      SQL
    end
  end
end
