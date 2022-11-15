with completed_lap_subquery as
         (select distinct on (effort_id) effort_id, case when kind = 1 then lap else lap - 1 end as completed_laps
          from split_times
                   join splits on splits.id = split_times.split_id
          order by effort_id, lap desc, distance_from_start desc, sub_split_bitkey desc)

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
       es.end_split_id,
       es.end_bitkey,
       lap,
       begin_time,
       elapsed_seconds,
       home_time_zone,
       laps_required != 1              as multiple_laps,
       completed_laps >= laps_required as finished
from efforts e
         join effort_segments es on es.effort_id = e.id
         join events ev on ev.id = e.event_id
         join event_groups eg on eg.id = ev.event_group_id
         join completed_lap_subquery cls on cls.effort_id = e.id
