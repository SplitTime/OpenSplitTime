# frozen_string_literal: true

class ProjectedArrivalsAtSplit
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  attribute :effort_id, :integer
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :bib_number, :integer
  attribute :projected_time, :datetime
  attribute :completed, :boolean
  attribute :stopped, :boolean

  alias_attribute :completed?, :completed
  alias_attribute :stopped?, :stopped

  def self.execute_query(*args)
    query = sql(*args)
    result = ::ActiveRecord::Base.connection.execute(query)
    result.map { |row| new(row) }
  end

  def self.sql(event_group_id, parameterized_split_name)
    <<~SQL.squish
      with event_ids as
               (select id as event_id
                from events
                where events.event_group_id = #{event_group_id}),

           completed_segments as
               (select distinct on (ast.effort_id) ast.effort_id,
                                                   course_id,
                                                   lap                  as completed_lap,
                                                   ast.split_id         as completed_split_id,
                                                   ast.sub_split_bitkey as completed_bitkey,
                                                   ast.elapsed_seconds  as elapsed_seconds,
                                                   absolute_time        as completed_time
                from split_times ast
                         join efforts on efforts.id = ast.effort_id
                         join splits on splits.id = ast.split_id
                where efforts.event_id in (select event_id from event_ids)
                order by ast.effort_id, lap desc, distance_from_start desc, sub_split_bitkey desc),

           completed_time_points as
               (select distinct on (completed_lap, completed_split_id, completed_bitkey) course_id,
                                                                                         completed_lap,
                                                                                         completed_split_id,
                                                                                         completed_bitkey
                from completed_segments),

           projected_time_points as
               (select ctp.*,
                       1             as started_lap,
                       ss.id         as started_split_id,
                       1             as started_bitkey,
                       completed_lap as projected_lap,
                       ps.id         as projected_split_id,
                       1             as projected_bitkey
                from completed_time_points ctp
                         join splits ps on ps.course_id = ctp.course_id and ps.parameterized_base_name = '#{parameterized_split_name}'
                         join splits ss on ss.course_id = ctp.course_id and ss.kind = 0),

           projected_seconds as
               (select ptp.*,
                       cst.elapsed_seconds - sst.elapsed_seconds as completed_seconds,
                       pst.elapsed_seconds - cst.elapsed_seconds as projected_seconds
                from projected_time_points ptp
                         join split_times sst on sst.lap = started_lap and sst.split_id = started_split_id and
                                                 sst.sub_split_bitkey = started_bitkey
                         join split_times cst on cst.lap = completed_lap and cst.split_id = completed_split_id and
                                                 cst.sub_split_bitkey = completed_bitkey and cst.effort_id = sst.effort_id
                         join split_times pst on pst.lap = projected_lap and pst.split_id = projected_split_id and
                                                 pst.sub_split_bitkey = projected_bitkey and pst.effort_id = sst.effort_id),

           projected_percentages as
               (select completed_lap,
                       completed_split_id,
                       completed_bitkey,
                       case
                           when completed_seconds = 0 then 0
                           else projected_seconds / completed_seconds end as projected_percentage
                from projected_seconds),

           grouped_projected_percentages as
               (select completed_lap, completed_split_id, completed_bitkey, avg(projected_percentage) as projected_percentage
                from projected_percentages
                group by completed_lap, completed_split_id, completed_bitkey),

           projected_times as
               (select distinct on (cs.effort_id) cs.effort_id,
                                                  completed_time +
                                                  ((cs.elapsed_seconds * projected_percentage)::int * interval '1 second') as projected_time,
                                                  projected_percentage <= 0                                                as completed,
                                                  st.id is not null                                                        as stopped
                from completed_segments cs
                         left join grouped_projected_percentages using (completed_lap, completed_split_id, completed_bitkey)
                         left join split_times st on st.effort_id = cs.effort_id and st.stopped_here = true
                order by cs.effort_id)

      select efforts.id as effort_id, first_name, last_name, bib_number, projected_time, completed, stopped
      from efforts
               join projected_times on projected_times.effort_id = efforts.id
      order by projected_time desc
    SQL
  end

  def expected?
    !completed? && !stopped?
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
