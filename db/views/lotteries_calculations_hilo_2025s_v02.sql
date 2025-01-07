with applicants as (
                   select organization_id,
                          person_id,
                          external_id,
                          gender
                   from historical_facts
                   where kind = 11
                     and year = 2025
                   ),

     last_reset_year as (
                   select organization_id, person_id, max(year) as last_reset_year
                   from historical_facts
                   where kind = 16
                     and person_id is not null
                   group by organization_id, person_id
                   ),

     applications_since_last_reset_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as applications_since_last_reset_count
                   from historical_facts
                            left join last_reset_year using (organization_id, person_id)
                   where historical_facts.kind = 11
                     and historical_facts.year < 2025
                     and historical_facts.year > coalesce(last_reset_year, 0)
                     and person_id is not null
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     finish_year_count as (
                   select organization_id, person_id, count(*) as finish_year_count
                   from efforts
                            join events on events.id = efforts.event_id
                            join event_groups on event_groups.id = events.event_group_id
                   where efforts.finished
                     and events.course_id in (
                                             select id
                                             from courses
                                             where courses.name ilike 'high lonesome 100'
                                             )
                     and extract(year from events.scheduled_start_time) < 2025
                   group by organization_id, person_id
                   ),

     volunteer_point_count as (
                   select historical_facts.organization_id, historical_facts.person_id, least(sum(historical_facts.quantity), 30) as volunteer_point_count
                   from historical_facts
                   where kind = 17
                     and year <= 2025
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     trail_work_hour_count as (
                   select historical_facts.organization_id, historical_facts.person_id, least(sum(historical_facts.quantity), 80) as trail_work_hour_count
                   from historical_facts
                   where kind = 18
                     and year <= 2025
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     all_counts as (
                   select applicants.organization_id,
                          applicants.person_id,
                          applicants.external_id,
                          applicants.gender,
                          last_reset_year,
                          coalesce(applications_since_last_reset_count, 0)::int          as application_count,
                          case
                              when finish_year_count is null then 0
                              when finish_year_count = 0 then 0
                              when finish_year_count = 1 then 0.5
                              when finish_year_count = 2 then 1
                              when finish_year_count = 3 then 1.5
                              else 0.5
                              end                                                        as weighted_finish_count,
                          coalesce(volunteer_point_count, 0)   as volunteer_points,
                          (coalesce(trail_work_hour_count, 0) / 8) as trail_work_shifts
                   from applicants
                            natural left join last_reset_year
                            natural left join applications_since_last_reset_count
                            natural left join finish_year_count
                            natural left join volunteer_point_count
                            natural left join trail_work_hour_count
                   )

select row_number() over () as id,
       organization_id,
       person_id,
       external_id,
       gender,
       case
           when gender = 0 then 'Male'
           else 'Female'
           end              as division,
       last_reset_year,
       application_count,
       weighted_finish_count,
       volunteer_points,
       trail_work_shifts,
       (
           pow(2, application_count + weighted_finish_count + 1)
               + (2 * ln(volunteer_points + trail_work_shifts + 1))
           )::int           as ticket_count
from all_counts
order by ticket_count desc;
