select es.effort_id,
       e.first_name,
       e.last_name,
       e.bib_number,
       e.city,
       e.state_code,
       e.country_code,
       e.age,
       e.gender,
       e.slug,
       es.begin_split_id,
       es.begin_bitkey,
       es.begin_split_kind,
       es.end_split_id,
       es.end_bitkey,
       es.end_split_kind,
       lap,
       begin_time,
       elapsed_seconds,
       home_time_zone,
       laps_required != 1                as multiple_laps,
       e.completed_laps >= laps_required as finished
from efforts e
         join effort_segments es on es.effort_id = e.id
         join events ev on ev.id = e.event_id
         join event_groups eg on eg.id = ev.event_group_id
