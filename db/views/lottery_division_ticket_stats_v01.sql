with entrant_list as (
    select distinct on(lottery_entrants.id) lottery_divisions.name as division_name,
                                            lottery_entrants.lottery_division_id as division_id,
                                            lottery_tickets.lottery_id,
                                            lottery_entrants.first_name,
                                            lottery_entrants.last_name,
                                            lottery_entrants.number_of_tickets,
                                            lottery_draws.id is not null
                                                and lottery_draws.position <= lottery_divisions.maximum_entries as drawn
    from lottery_entrants
             join lottery_divisions on lottery_divisions.id = lottery_entrants.lottery_division_id
             join lottery_tickets on lottery_tickets.lottery_entrant_id = lottery_entrants.id
             left join lottery_draws on lottery_draws.lottery_ticket_id = lottery_tickets.id
    order by lottery_entrants.id, lottery_draws.id
)

select lottery_id, division_id, division_name, number_of_tickets, count(*) filter (where drawn) as drawn_entrants_count, count(*) as entrants_count
from entrant_list
group by lottery_id, division_id, division_name, number_of_tickets
order by lottery_id, division_id, division_name, number_of_tickets
