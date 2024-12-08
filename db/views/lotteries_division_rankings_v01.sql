with ranked_draws as (
                     select lottery_tickets.lottery_entrant_id,
                            rank() over division_window as division_rank
                     from lottery_tickets
                              join lottery_draws on lottery_draws.lottery_ticket_id = lottery_tickets.id
                              join lottery_entrants on lottery_entrants.id = lottery_tickets.lottery_entrant_id
                     window division_window as (partition by lottery_entrants.lottery_division_id order by lottery_draws.created_at)
                     )

select lottery_entrants.id as lottery_entrant_id,
       lottery_divisions.name as division_name,
       division_rank,
       case
           when division_rank <= maximum_entries then 'accepted'
           when division_rank <= maximum_entries + maximum_wait_list then 'waitlisted'
           else 'not_drawn' end as draw_status
from lottery_entrants
         left join ranked_draws on ranked_draws.lottery_entrant_id = lottery_entrants.id
         join lottery_divisions on lottery_entrants.lottery_division_id = lottery_divisions.id
;
