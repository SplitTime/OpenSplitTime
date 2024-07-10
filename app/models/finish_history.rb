# frozen_string_literal: true

class FinishHistory < ::ApplicationQuery
  attribute :person_id, type: Integer
  attribute :begin_time, type: Integer
  attribute :best_time_seconds, type: Integer
  attribute :current_time_seconds, type: Integer
  attribute :number_of_finishes, type: Integer

  # @param [Integer] event_id
  # @return [String]
  def self.sql(event_id:)
    <<~SQL.squish
with 
  main_subquery as (
	select efforts.person_id, efforts.event_id, effort_segments.*
	from events
	  left join course_group_courses on course_group_courses.course_id = events.course_id
	  left join course_groups on course_groups.id = course_group_courses.course_group_id
	  left join course_group_courses all_cgc on all_cgc.course_group_id = course_groups.id
	  join events relevant_events on (relevant_events.course_id = coalesce(all_cgc.course_id, events.course_id)) 
	  join efforts on efforts.event_id = relevant_events.id
	  join people on people.id = efforts.person_id
	  join effort_segments on effort_segments.effort_id = efforts.id 
                        and effort_segments.begin_split_kind = #{Split.kinds[:start]} 
                        and effort_segments.end_split_kind = #{Split.kinds[:finish]}
	where events.id = #{event_id}
    and relevant_events.scheduled_start_time <= (select scheduled_start_time from events where events.id = #{event_id})
	  and people.id in (select person_id from efforts where efforts.event_id = #{event_id})
	order by efforts.person_id, effort_segments.elapsed_seconds
  ),
  
  finish_counts as (
    select person_id, count(*) as number_of_finishes
    from main_subquery
    group by person_id
  ),

  current_finish_seconds as (
    select person_id, main_subquery.elapsed_seconds
    from main_subquery
    where main_subquery.event_id = #{event_id}
  )
  
select distinct on (main_subquery.person_id) main_subquery.person_id, 
                                             main_subquery.begin_time, 
                                             main_subquery.elapsed_seconds as best_time_seconds, 
                                             current_finish_seconds.elapsed_seconds as current_time_seconds, 
                                             number_of_finishes
from main_subquery
left join finish_counts on finish_counts.person_id = main_subquery.person_id
left join current_finish_seconds on current_finish_seconds.person_id = main_subquery.person_id;
    SQL
  end
end
