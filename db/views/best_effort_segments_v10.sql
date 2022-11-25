select es.effort_id,
       e.event_id,
       e.first_name,
       e.last_name,
       e.bib_number,
       e.city,
       e.state_code,
       e.country_code,
       e.age,
       e.gender,
       e.slug,
       e.person_id,
       concat(e.gender, ':', e.age / 10 * 10) as age_group,
       es.begin_split_id,
       es.begin_bitkey,
       es.begin_split_kind,
       es.end_split_id,
       es.end_bitkey,
       es.end_split_kind,
       es.lap,
       es.begin_time,
       es.elapsed_seconds,
       eg.home_time_zone,
       es.course_id,
       ev.laps_required != 1             as multiple_laps,
       e.completed_laps >= laps_required as finished,
       es.begin_split_kind = 0 and es.end_split_kind = 1 as full_course,
       c.name as course_name
from efforts e
    join effort_segments es on es.effort_id = e.id
    join events ev on ev.id = e.event_id
    join event_groups eg on eg.id = ev.event_group_id
    join courses c on c.id = ev.course_id
