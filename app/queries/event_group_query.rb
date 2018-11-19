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

  def self.bib_sub_split_rows(args)
    event_group = args[:event_group]
    parameterized_split_name = args[:split_name].parameterize
    bitkey = args[:bitkey]
    order_sql = sql_order_from_hash(args[:sort], permitted_sort_fields, :sortable_bib_number)
    home_time_zone = event_group.home_time_zone
    time_zone = ActiveSupport::TimeZone.find_tzinfo(home_time_zone).identifier

    query = <<~SQL
      set timezone='#{time_zone}';
  
      with raw_times_subquery as
        (select ef.id as effort_id, ef.first_name, ef.last_name, rt.bib_number, rt.sortable_bib_number,
                         json_agg(json_build_object('id', rt.id,
                                                    'military_time', case when rt.absolute_time is null then rt.entered_time else to_char((rt.absolute_time at time zone 'UTC'), 'HH24:MI:SS') end,
                                                    'source', rt.source,
                                                    'created_by', rt.created_by)
                                  order by case when rt.absolute_time is null then rt.entered_time else to_char((rt.absolute_time at time zone 'UTC'), 'HH24:MI:SS') end) as raw_times_attributes
        from raw_times rt
        left join efforts ef on ef.event_id in (select id from events where events.event_group_id = #{event_group.id}) and ef.bib_number::text = rt.bib_number
        where rt.event_group_id = #{event_group.id} and rt.parameterized_split_name = '#{parameterized_split_name}' and rt.bitkey = #{bitkey}
        group by ef.id, ef.first_name, ef.last_name, rt.bib_number, rt.sortable_bib_number),
  
      split_times_subquery as
        (select ef.id as effort_id, 
                min(st.absolute_time at time zone 'UTC') as sortable_time,
                json_agg(json_build_object('id', st.id, 
                                           'lap', st.lap, 
                                           'military_time', to_char((st.absolute_time at time zone 'UTC'), 'HH24:MI:SS')) 
                                  order by st.lap) as split_times_attributes
        from split_times st
          inner join efforts ef on ef.id = st.effort_id
          inner join events ev on ev.id = ef.event_id
          inner join splits s on s.id = st.split_id
        where ef.event_id in (select id from events where events.event_group_id = #{event_group.id}) and s.parameterized_base_name = '#{parameterized_split_name}' and st.sub_split_bitkey = #{bitkey}
        group by ef.id)
  
      select rts.*, sts.sortable_time, sts.split_times_attributes
      from raw_times_subquery rts
        left join split_times_subquery sts on rts.effort_id = sts.effort_id
      order by #{order_sql}
    SQL
    query.squish
  end

  def self.permitted_sort_fields
    [:sortable_bib_number, :sortable_time, :first_name, :last_name]
  end
end
