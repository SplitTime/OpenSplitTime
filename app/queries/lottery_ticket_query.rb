class LotteryTicketQuery < BaseQuery
  # This method returns a fixed string with no Ruby string injection. To use it, call:
  # sanitized_sql = ActiveRecord::Base.sanitize_sql([sql, { lottery_id: lottery_id, beginning_reference_number: beginning_reference_number }])
  # ActiveRecord::Base.connection.execute(sanitized_sql, "Lottery Ticket Bulk Insert")
  def self.insert_lottery_tickets
    <<~SQL.squish
      with ticket_data as (
                              select e.id                                    as lottery_entrant_id,
                                     d.lottery_id                            as lottery_id,
                                     generate_series(1, e.number_of_tickets) as ticket_number,
                                     now()                                   as created_at,
                                     now()                                   as updated_at
                              from lottery_entrants e
                                       join lottery_divisions d on e.lottery_division_id = d.id
                                       join lotteries l on d.lottery_id = l.id
                              where l.id = :lottery_id
                              ),
           shuffled_tickets as (
                              select ticket_data.*,
                                     random() as rand_val
                              from ticket_data
                              ),
           ranked_tickets as (
                              select st.*,
                                     row_number() over (order by st.rand_val) + :beginning_reference_number - 1 as reference_number
                              from shuffled_tickets st
                              )
      insert
      into lottery_tickets (lottery_id, lottery_entrant_id, reference_number, created_at, updated_at)
      select lottery_id,
             lottery_entrant_id,
             reference_number,
             created_at,
             updated_at
      from ranked_tickets
    SQL
  end
end
