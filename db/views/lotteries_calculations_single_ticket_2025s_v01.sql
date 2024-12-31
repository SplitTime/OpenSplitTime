with applicants as (
                   select historical_facts.organization_id,
                          historical_facts.person_id,
                          any_value(historical_facts.external_id) as external_id,
                          any_value(historical_facts.gender)      as gender
                   from historical_facts
                   where kind = 11
                     and year = 2024
                   group by historical_facts.organization_id, historical_facts.person_id
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
       1                    as ticket_count
from applicants;
