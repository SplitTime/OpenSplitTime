# frozen_string_literal: true

class EffortQuery < BaseQuery

  def self.rank_and_status(args = {})
    select_sql = sql_select_from_string(args[:fields], permitted_column_names, '*')
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, 'overall_rank')
    query = <<-SQL
      with
        existing_scope as (#{existing_scope_sql}),

        efforts_scoped as 
          (select efforts.*
           from efforts
           inner join existing_scope on existing_scope.id = efforts.id),

        start_split_times as
          (select effort_id, absolute_time
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = 1 and kind = 0 and effort_id in (select id from efforts_scoped)
           order by effort_id),

        stopped_split_times as 
          (select  split_times.id as stopped_split_time_id, 
                   split_times.lap as stopped_lap, 
                   split_times.split_id as stopped_split_id, 
                   split_times.sub_split_bitkey as stopped_bitkey, 
                   split_times.absolute_time as stopped_absolute_time, 
                   split_times.effort_id
           from split_times
           where effort_id in (select id from efforts_scoped) and stopped_here = true),

        course_subquery as 
          (select courses.id as course_id, splits.distance_from_start as course_distance
           from courses
           inner join splits on splits.course_id = courses.id
           where splits.kind = 1),

        base_subquery as 
          (select distinct on(efforts_scoped.id) 
              efforts_scoped.*,
              events.laps_required,
              events.start_time as event_start_time,
              events.home_time_zone as event_home_zone,
              splits.base_name as final_split_name,
              splits.distance_from_start as final_lap_distance,
              split_times.lap as final_lap,
              split_times.split_id as final_split_id, 
              split_times.sub_split_bitkey as final_bitkey,
              split_times.absolute_time as final_absolute_time,
              sst.absolute_time as start_time,
              extract(epoch from(sst.absolute_time - events.start_time)) as start_offset,
              extract(epoch from (split_times.absolute_time - sst.absolute_time)) as final_time_from_start,
              split_times.id as final_split_time_id,
              stopped_split_time_id,
              stopped_lap,
              stopped_split_id,
              stopped_bitkey,
              stopped_absolute_time,
              course_distance,
              case when splits.kind = 1 then true else false end as final_lap_complete,
              case when split_times.lap > 1 or splits.kind in (1, 2) then true else false end as beyond_start
           from efforts_scoped
              left join split_times on split_times.effort_id = efforts_scoped.id 
              left join splits on splits.id = split_times.split_id
              left join events on events.id = efforts_scoped.event_id
              left join course_subquery on events.course_id = course_subquery.course_id
              left join stopped_split_times stop_st on split_times.effort_id = stop_st.effort_id
              left join start_split_times sst on split_times.effort_id = sst.effort_id
           order by efforts_scoped.id, 
                    final_lap desc,
                    final_lap_distance desc, 
                    final_bitkey desc),

        distance_subquery as 
          (select *, 
              case when final_lap is null then false else true end as started,
              final_lap as laps_started,
              case when final_lap_complete is true then final_lap else final_lap - 1 end as laps_finished,
              (final_lap - 1) * course_distance + final_lap_distance as final_distance
           from base_subquery),

        finished_subquery as 
          (select *,
              case 
              when laps_required = 0 then
                case when stopped_split_time_id is null then false else true end  
              else
                case when laps_finished >= laps_required then true else false end 
              end
              as finished,
              case
                when not started and checked_in and scheduled_start_time < current_timestamp then true else false
              end
              as ready_to_start
           from distance_subquery),

        stopped_subquery as 
          (select *,
              case when finished or stopped_split_time_id is not null then true else false end as stopped
           from finished_subquery),

        main_subquery as 
          (select *,
              case when stopped and not finished then true else false end as dropped
           from stopped_subquery)

      select #{select_sql},
          rank() over 
            (order by started desc,
                      dropped, 
                      final_lap desc nulls last, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time_from_start, 
                      gender desc, 
                      age desc) 
          as overall_rank, 
          rank() over 
            (partition by gender 
             order by started desc,
                      dropped, 
                      final_lap desc nulls last, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time_from_start, 
                      gender desc, 
                      age desc) 
          as gender_rank
      from main_subquery
      order by #{order_sql}
    SQL
    query.squish
  end

  def self.over_segment(segment)
    begin_id = segment.begin_id
    begin_bitkey = segment.begin_bitkey
    end_id = segment.end_id
    end_bitkey = segment.end_bitkey

    query = <<-sql
      with
        existing_scope as (#{existing_scope_sql}),
        
        efforts_scoped as 
            (select efforts.*
             from efforts
             inner join existing_scope on existing_scope.id = efforts.id),
                                       
        start_split_times as
          (select effort_id, absolute_time
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = 1 and kind = 0 and effort_id in (select id from efforts_scoped)
           order by effort_id),

        stopped_split_times as 
            (select id as stopped_split_time_id, 
                    lap as stopped_lap, 
                    split_id as stopped_split_id, 
                    sub_split_bitkey as stopped_bitkey, 
                    absolute_time as stopped_time, 
                    effort_id
             from split_times
             where stopped_here = true and effort_id in (select id from efforts_scoped)),
                                      
        farthest_split_times as 
            (select distinct on(st.effort_id)
                    st.effort_id, 
                    st.lap as final_lap,
                    s.distance_from_start as final_lap_distance,
                    st.sub_split_bitkey as final_bitkey,
                    case when s.kind = 1 then true else false end as final_lap_complete,
                    case when s.kind = 1 then st.lap else st.lap - 1 end as laps_finished
             from split_times st
                left join splits s on s.id = st.split_id
             where st.effort_id in (select id from efforts_scoped)
             order by st.effort_id, 
                      final_lap desc,
                      final_lap_distance desc, 
                      final_bitkey desc),
                                          
        main_subquery as   
            (select e1.*,
                    absolute_time_begin as segment_start_time,
                    extract(epoch from(absolute_time_end - absolute_time_begin)) as segment_seconds
             from 
                      (select efforts_scoped.*, 
                              events.start_time as event_start_time, 
                              events.home_time_zone as event_home_zone, 
                              split_times.effort_id, 
                              split_times.absolute_time as absolute_time_begin, 
                              split_times.lap, 
                              split_times.split_id, 
                              split_times.sub_split_bitkey,
                              events.laps_required,
                              event_groups.concealed as event_group_concealed
                      from efforts_scoped
                        inner join split_times on split_times.effort_id = efforts_scoped.id 
                        inner join events on events.id = efforts_scoped.event_id
                        inner join event_groups on event_groups.id = events.event_group_id
                      where split_times.split_id = #{begin_id} and split_times.sub_split_bitkey = #{begin_bitkey}) 
                  as e1, 
                      (select efforts_scoped.id, 
                              split_times.effort_id, 
                              split_times.absolute_time as absolute_time_end, 
                              split_times.lap, 
                              split_times.split_id, 
                              split_times.sub_split_bitkey 
                      from efforts_scoped
                      inner join split_times on split_times.effort_id = efforts_scoped.id 
                      where split_times.split_id = #{end_id} and split_times.sub_split_bitkey = #{end_bitkey}) 
                  as e2 
                  where (e1.effort_id = e2.effort_id and e1.lap = e2.lap))
                
      select main_subquery.*, 
              lap, 
              rank() over (order by segment_seconds, gender, -age, lap) as overall_rank, 
              rank() over (partition by gender order by segment_seconds, -age, lap) as gender_rank,
              case 
              when main_subquery.laps_required = 0 then
                case when stopped_split_time_id is null then false else true end  
              else
                case when laps_finished >= laps_required then true else false end 
              end
              as finished,
              sst.absolute_time as start_time
      from main_subquery 
        left join start_split_times sst on sst.effort_id = main_subquery.effort_id
        left join stopped_split_times on stopped_split_times.effort_id = main_subquery.effort_id
        left join farthest_split_times on farthest_split_times.effort_id = main_subquery.effort_id
      where event_group_concealed = 'f'
      order by overall_rank
    sql
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
