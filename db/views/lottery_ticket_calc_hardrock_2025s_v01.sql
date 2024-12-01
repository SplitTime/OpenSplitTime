with applicants as (
                   select historical_facts.organization_id,
                          historical_facts.person_id,
                          any_value(historical_facts.gender) as gender,
                          coalesce(bool_or(event_groups.organization_id = historical_facts.organization_id and
                                           (efforts.finished or (efforts.started and extract(year from events.scheduled_start_time) < 2021))),
                                   false)                    as finisher
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

     latest_vmulti as (
                   select ranked_vmultis.organization_id,
                          ranked_vmultis.person_id,
                          ranked_vmultis.year     as latest_vmulti_year,
                          ranked_vmultis.quantity as latest_vmulti_year_count
                   from (
                        select historical_facts.organization_id,
                               historical_facts.person_id,
                               historical_facts.year,
                               historical_facts.quantity,
                               row_number()
                               over (partition by historical_facts.organization_id, historical_facts.person_id order by historical_facts.year desc) as rank
                        from historical_facts
                        where historical_facts.kind = 3
                          and historical_facts.year < 2024
                        ) ranked_vmultis
                   where rank = 1
                   ),

     volunteer_year_count as (
                   select historical_facts.organization_id, historical_facts.person_id, count(*) as volunteer_year_count
                   from historical_facts
                            left join latest_vmulti using (organization_id, person_id)
                   where kind = 1
                     and year < 2025
                     and year > latest_vmulti_year
                   group by historical_facts.organization_id, historical_facts.person_id
                   ),

     major_volunteer_year_count as (
                   select historical_facts.organization_id, historical_facts.person_id, 1 as major_volunteer_year_count
                   from historical_facts
                   where historical_facts.kind = 2
                     and historical_facts.year = 2024
                   )

select applicants.organization_id,
       applicants.person_id,
       case
           when gender = 0 and finisher then 'Male Finishers'
           when gender = 0 then 'Male Nevers'
           when finisher then 'Female Finishers'
           else 'Female Nevers'
           end as division,
       case
           when finisher
               then coalesce(dns_since_last_start_count, 0) +
                    coalesce(finish_year_count, 0) +
                    (coalesce(volunteer_year_count, 0) + coalesce(latest_vmulti_year_count, 0)) / 5 +
                    coalesce(major_volunteer_year_count, 0) +
                    1
           else pow(2,
                    coalesce(dns_since_last_reset_count, 0) +
                    coalesce(finish_year_count, 0) +
                    (coalesce(volunteer_year_count, 0) + coalesce(latest_vmulti_year_count, 0)) / 5 +
                    coalesce(major_volunteer_year_count, 0)
                )
           end as ticket_count

from applicants
         natural left join dns_since_last_start_count
         natural left join dns_since_last_reset_count
         natural left join finish_year_count
         natural left join latest_vmulti
         natural left join volunteer_year_count
         natural left join major_volunteer_year_count
;