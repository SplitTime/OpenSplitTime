# frozen_string_literal: true

class EventGroupQuery < BaseQuery

  def self.not_expected_bibs(event_group_id, split_name)
    parameterized_split_name = split_name.parameterize
    query = <<-SQL
      with relevant_events as
        (select id
        from events
        where event_group_id = #{event_group_id}),
        
      latest_split_times as
        (select distinct on (effort_id) 
            split_times.id, effort_id, lap, distance_from_start, sub_split_bitkey, 
            case when stopped_here then true else false end as stopped
         from split_times
         inner join splits on splits.id = split_times.split_id
         inner join efforts on efforts.id = split_times.effort_id
         where efforts.event_id in (select id from relevant_events)
         order by effort_id, stopped desc, lap desc, distance_from_start desc, sub_split_bitkey desc),
         
      distances as
        (select event_id, distance_from_start as subject_distance
         from events
         inner join aid_stations on aid_stations.event_id = events.id
         inner join splits on splits.id = aid_stations.split_id
         where events.id in (select id from relevant_events) 
           and splits.parameterized_base_name = '#{parameterized_split_name}'),
         
      relevant_efforts as
        (select efforts.id, bib_number, stopped, subject_distance,
             latest_split_times.distance_from_start as farthest_distance
         from efforts
         left join latest_split_times on latest_split_times.effort_id = efforts.id
         left join distances on distances.event_id = efforts.event_id
         where efforts.event_id in (select id from relevant_events)
         order by efforts.id)
         
      select bib_number
      from relevant_efforts
      where stopped is true
         or farthest_distance is null
         or subject_distance is null
         or farthest_distance >= subject_distance
      order by bib_number
    SQL
    query.squish
  end
end
