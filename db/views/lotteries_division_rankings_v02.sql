with ranked_draws as (
                     select lottery_tickets.lottery_entrant_id,
                            rank() over division_window as division_rank
                     from lottery_tickets
                              join lottery_draws on lottery_draws.lottery_ticket_id = lottery_tickets.id
                              join lottery_entrants on lottery_entrants.id = lottery_tickets.lottery_entrant_id
                     window division_window as (
                             partition by lottery_entrants.lottery_division_id
                             order by case
                                          when withdrawn is false or withdrawn is null then 0
                                          when withdrawn is true then 1 end,
                                 lottery_draws.created_at
                             )
                     )

select lottery_entrants.id    as lottery_entrant_id,
       lottery_divisions.name as division_name,
       division_rank,
--        accepted: 0
--        waitlisted: 1
--        drawn_beyond_waitlist: 2
--        not_drawn: 3
--        withdrawn: 4
       case
           when lottery_entrants.withdrawn then 4
           when division_rank <= maximum_entries then 0
           when division_rank <= maximum_entries + maximum_wait_list then 1
           when division_rank is not null then 2
           else 3 end         as draw_status
from lottery_entrants
         left join ranked_draws on ranked_draws.lottery_entrant_id = lottery_entrants.id
         join lottery_divisions on lottery_entrants.lottery_division_id = lottery_divisions.id
;
