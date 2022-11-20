select p.id as person_id,
       p.first_name,
       p.last_name,
       p.gender,
       p.city,
       p.state_code,
       p.country_code,
       p.slug,
       cg.id as course_group_id,
       count(e.id) as finish_count

from course_groups cg
    join course_group_courses cgc on cgc.course_group_id = cg.id
    join courses c on c.id = cgc.course_id
    join events e on e.course_id = c.id
    join efforts ef on ef.event_id = e.id
    join people p on ef.person_id = p.id
where ef.finished = true
group by cg.id, p.id
