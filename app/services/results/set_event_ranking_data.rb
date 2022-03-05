# frozen_string_literal: true

module Results
  class SetEventRankingData
    def self.perform!(event_id)
      new(event_id).perform!
    end

    def initialize(event_id)
      @event_id = event_id
    end

    def perform!
      ::ActiveRecord::Base.connection.execute(query)
    end

    private

    attr_reader :event_id

    def query
      <<~SQL.squish
with scoped_efforts as (
         select efforts.id, efforts.event_id, efforts.gender
         from efforts
         where efforts.event_id = #{event_id}
     ),

     course_subquery as (
         select courses.id                 as course_id,
                splits.distance_from_start as course_distance
         from courses
                  join splits on splits.course_id = courses.id
                  join events on events.course_id = courses.id
         where splits.kind = 1
           and events.id = #{event_id}
     ),

     start_times as (
         select distinct on (effort_id) effort_id, absolute_time
         from split_times
                  inner join splits on splits.id = split_times.split_id
                  inner join scoped_efforts on scoped_efforts.id = split_times.effort_id
         where lap = 1
           and kind = 0
         order by effort_id
     ),

     beyond_start_efforts as (
         select distinct on (effort_id) effort_id
         from split_times
                  join splits on splits.id = split_times.split_id
                  join scoped_efforts on scoped_efforts.id = split_times.effort_id
         where kind != 0
            or lap != 1
         order by effort_id
     ),

     stopped_split_times as (
         select split_times.effort_id,
                split_times.id               as stopped_split_time_id,
                split_times.lap              as stopped_lap,
                split_times.split_id         as stopped_split_id,
                split_times.sub_split_bitkey as stopped_bitkey,
                split_times.absolute_time    as stopped_absolute_time
         from split_times
                  join scoped_efforts on scoped_efforts.id = split_times.effort_id
         where stopped_here = true
     ),

     final_split_times as (
         select distinct on (scoped_efforts.id) scoped_efforts.id            as effort_id,
                                                split_times.id               as final_split_time_id,
                                                splits.base_name             as final_split_name,
                                                splits.distance_from_start   as final_lap_distance,
                                                splits.vert_gain_from_start  as final_lap_vert_gain,
                                                split_times.lap              as final_lap,
                                                split_times.split_id         as final_split_id,
                                                split_times.sub_split_bitkey as final_bitkey,
                                                split_times.absolute_time    as final_absolute_time,
                                                split_times.elapsed_seconds  as final_elapsed_seconds,
                                                splits.kind = 1              as final_lap_complete
         from scoped_efforts
                  join split_times on split_times.effort_id = scoped_efforts.id
                  join splits on splits.id = split_times.split_id
         order by scoped_efforts.id,
                  final_lap desc,
                  final_lap_distance desc,
                  final_bitkey desc
     ),

     base_subquery as (
         select scoped_efforts.id                                                  as effort_id,
                scoped_efforts.gender,
                events.laps_required,
                stopped_split_time_id,
                stopped_lap,
                stopped_split_id,
                stopped_bitkey,
                stopped_absolute_time,
                course_distance,
                final_split_time_id,
                final_lap,
                final_lap_distance,
                final_bitkey,
                final_elapsed_seconds,
                final_lap is not null                                              as started,
                bse.effort_id is not null                                          as beyond_start,
                case when final_lap_complete then final_lap else final_lap - 1 end as laps_finished
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

     ranking_subquery as (
         select *,
                case
                    when beyond_start then
                                rank() over
                            (order by beyond_start desc,
                                started desc,
                                dropped,
                                final_lap desc nulls last,
                                final_lap_distance desc,
                                final_bitkey desc,
                                final_elapsed_seconds)
                    end
                    as overall_rank,
                case
                    when beyond_start then
                                rank() over
                            (partition by gender
                            order by beyond_start desc,
                                started desc,
                                dropped,
                                final_lap desc nulls last,
                                final_lap_distance desc,
                                final_bitkey desc,
                                final_elapsed_seconds)
                    end
                    as gender_rank,
                lag(effort_id) over
                    (order by beyond_start desc,
                        started desc,
                        dropped,
                        final_lap desc nulls last,
                        final_lap_distance desc,
                        final_bitkey desc,
                        final_elapsed_seconds)
                    as prior_effort_id,
                lead(effort_id) over
                    (order by beyond_start desc,
                        started desc,
                        dropped,
                        final_lap desc nulls last,
                        final_lap_distance desc,
                        final_bitkey desc,
                        final_elapsed_seconds)
                    as next_effort_id
         from base_with_status
     ),

     update_data as (
         select effort_id,
                overall_rank,
                gender_rank,
                prior_effort_id,
                next_effort_id,
                stopped_split_time_id,
                final_split_time_id,
                started,
                beyond_start,
                stopped,
                dropped,
                finished
         from ranking_subquery
         order by effort_id
     )

update efforts
set overall_rank          = update_data.overall_rank,
    gender_rank           = update_data.gender_rank,
    prior_effort_id       = update_data.prior_effort_id,
    next_effort_id        = update_data.next_effort_id,
    stopped_split_time_id = update_data.stopped_split_time_id,
    final_split_time_id   = update_data.final_split_time_id,
    started               = update_data.started,
    beyond_start          = update_data.beyond_start,
    stopped               = update_data.stopped,
    dropped               = update_data.dropped,
    finished              = update_data.finished
from update_data
where efforts.id = update_data.effort_id
      SQL
    end
  end
end
