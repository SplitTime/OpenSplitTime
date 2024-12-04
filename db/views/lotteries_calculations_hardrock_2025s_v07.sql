with applicants as (
                   select historical_facts.organization_id,
                          historical_facts.person_id,
                          any_value(historical_facts.external_id) as external_id,
                          any_value(historical_facts.gender)      as gender,
                          coalesce(bool_or(event_groups.organization_id = historical_facts.organization_id and
                                           (efforts.finished or (efforts.started and extract(year from events.scheduled_start_time) < 2021))),
                                   false)                         as finisher
                   from historical_facts
                            left join efforts on efforts.person_id = historical_facts.person_id
                            left join events on events.id = efforts.event_id
                            left join event_groups on event_groups.id = events.event_group_id
                   where kind = 11
                     and year = 2024
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     last_start_year as (
                   select organization_id, person_id, max(extract(year from events.scheduled_start_time)) as year
                   from efforts
                            join events on events.id = efforts.event_id
                            join event_groups on event_groups.id = events.event_group_id
                   where efforts.started
                   group by organization_id, person_id
                   order by person_id
                   ),

     dns_since_last_start_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as dns_since_last_start_count
                   from historical_facts
                            left join last_start_year using (organization_id, person_id)
                   where historical_facts.kind = 0
                     and historical_facts.year < 2025
                     and historical_facts.year > coalesce(last_start_year.year, 0)
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     last_reset_year as (
                   select organization_id, person_id, max(extract(year from events.scheduled_start_time)) as year
                   from efforts
                            join events on events.id = efforts.event_id
                            join event_groups on event_groups.id = events.event_group_id
                   where efforts.finished
                      or (efforts.started and extract(year from events.scheduled_start_time) > 2023)
                   group by organization_id, person_id
                   ),

     dns_since_last_reset_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as dns_since_last_reset_count
                   from historical_facts
                            left join last_reset_year using (organization_id, person_id)
                   where historical_facts.kind = 0
                     and historical_facts.year < 2025
                     and historical_facts.year > coalesce(last_reset_year.year, 0)
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     finish_year_count as (
                   select organization_id, person_id, count(*) as finish_year_count
                   from efforts
                            join events on events.id = efforts.event_id
                            join event_groups on event_groups.id = events.event_group_id
                   where efforts.finished
                     and extract(year from events.scheduled_start_time) < 2025
                   group by organization_id, person_id
                   ),

     vmulti_year_count as (
                   select historical_facts.organization_id, historical_facts.person_id, historical_facts.quantity as vmulti_year_count
                   from historical_facts
                   where kind = 3
                   ),

     volunteer_year_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as volunteer_year_count
                   from historical_facts
                   where kind = 1
                     and year < 2025
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     major_volunteer_year_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as major_volunteer_year_count
                   from historical_facts
                   where historical_facts.kind = 2
                     and historical_facts.year = 2024
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     all_counts as (
                   select applicants.organization_id,
                          applicants.person_id,
                          applicants.external_id,
                          applicants.finisher,
                          applicants.gender,
                          (case
                               when finisher
                                   then coalesce(dns_since_last_start_count, 0)
                               else coalesce(dns_since_last_reset_count, 0)
                              end)::int                                   as dns_ticket_count,
                          coalesce(finish_year_count, 0)::int             as finish_ticket_count,
                          ((coalesce(volunteer_year_count, 0)
                              + coalesce(vmulti_year_count, 0)) / 5)::int as volunteer_ticket_count,
                          coalesce(major_volunteer_year_count, 0)::int    as volunteer_major_ticket_count
                   from applicants
                            natural left join dns_since_last_start_count
                            natural left join dns_since_last_reset_count
                            natural left join finish_year_count
                            natural left join vmulti_year_count
                            natural left join volunteer_year_count
                            natural left join major_volunteer_year_count
                   )

select row_number() over () as id,
       organization_id,
       person_id,
       external_id,
       gender,
       finisher,
       case
           when gender = 0 and finisher then 'Male Finishers'
           when gender = 0 then 'Male Nevers'
           when finisher then 'Female Finishers'
           else 'Female Nevers'
           end              as division,
       dns_ticket_count,
       finish_ticket_count,
       volunteer_ticket_count,
       volunteer_major_ticket_count,
       (case
            when finisher then
                dns_ticket_count
                    + finish_ticket_count
                    + volunteer_ticket_count
                    + volunteer_major_ticket_count
                    + 1
            else
                pow(2, dns_ticket_count
                    + volunteer_ticket_count
                    + volunteer_major_ticket_count)
           end)::int
                            as ticket_count
from all_counts;
