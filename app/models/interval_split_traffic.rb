# frozen_string_literal: true

class IntervalSplitTraffic < ::ApplicationQuery
  attribute :end_time, :datetime
  attribute :event_ids, :integer_array_from_string
  attribute :finished_in_counts, :integer_array_from_string
  attribute :finished_out_counts, :integer_array_from_string
  attribute :in_counts, :integer_array_from_string
  attribute :out_counts, :integer_array_from_string
  attribute :short_names, :string_array_from_string
  attribute :start_time, :datetime
  attribute :total_finished_in_count, :integer
  attribute :total_finished_out_count, :integer
  attribute :total_in_count, :integer
  attribute :total_out_count, :integer

  Counts = Struct.new(:event_id, :name, :in, :out, :finished_in, :finished_out)
  ROW_LIMIT = 300

  def self.execute_query(event_group:, split_name:, band_width:)
    parameterized_split_name = split_name.parameterize
    band_width /= 1.second
    split_times = ::SplitTime.joins(effort: :event).joins(:split).where(splits: {parameterized_base_name: parameterized_split_name}, events: {event_group: event_group})
    max = split_times.maximum(:absolute_time)
    min = split_times.minimum(:absolute_time)
    return [] unless max.present? && min.present?

    time_span = max - min
    return if time_span / band_width > ROW_LIMIT

    super
  end

  # @param [EventGroup] event_group
  # @param [String] split_name
  # @param [ActiveSupport::Duration] band_width
  # @return [String]
  def self.sql(event_group:, split_name:, band_width:)
    parameterized_split_name = split_name.parameterize
    band_width /= 1.second

    <<~SQL.squish
      with 
      scoped_split_times as (
        select st.effort_id, st.sub_split_bitkey, st.lap, st.absolute_time, ef.event_id
        from split_times st
          inner join efforts ef on ef.id = st.effort_id
          inner join events ev on ev.id = ef.event_id
          inner join splits s on s.id = st.split_id
        where event_group_id = #{event_group.id} and s.parameterized_base_name = '#{parameterized_split_name}'
        order by absolute_time
      ),
      
      finish_split_times as (
        select effort_id, lap
        from efforts ef
          inner join split_times st on st.effort_id = ef.id
          inner join splits s on s.id = st.split_id
        where ef.id in (select effort_id from scoped_split_times) and s.kind = 1
        order by ef.id
      ),
         
      interval_starts as (
        select *
        from generate_series((select min(to_timestamp(floor((extract(epoch from absolute_time)) / #{band_width}) * #{band_width})) from scoped_split_times), 
                             (select max(to_timestamp(floor((extract(epoch from absolute_time)) / #{band_width}) * #{band_width})) + interval '#{band_width} seconds' from scoped_split_times), 
                              interval '#{band_width} seconds') time
      ),
         
      intervals as (
        select time as start_time, lead(time) over(order by time) as end_time 
        from interval_starts
      ),
      
      intervals_with_event_ids as (
        select start_time, end_time, event_ids.id as event_id
        from intervals
          cross join (select id from events where events.event_group_id = #{event_group.id}) event_ids
      ),

      ungrouped_results as (
        select i.event_id,
             short_name,
             i.start_time,
             i.end_time, 
             count(case when st.sub_split_bitkey = 1 then 1 else null end) as in_count, 
             count(case when st.sub_split_bitkey = 64 then 1 else null end) as out_count,
             count(case when st.sub_split_bitkey = 1 and fst.effort_id is not null then 1 else null end) as finished_in_count,
             count(case when st.sub_split_bitkey = 64 and fst.effort_id is not null then 1 else null end) as finished_out_count
        from scoped_split_times st
          left join finish_split_times fst
            on fst.effort_id = st.effort_id and fst.lap = st.lap
          right join intervals_with_event_ids i
            on st.absolute_time >= i.start_time and st.absolute_time < i.end_time and st.event_id = i.event_id
          left join events on events.id = i.event_id
        where i.end_time is not null
        group by i.start_time, i.end_time, i.event_id, short_name
        order by i.start_time, i.event_id
      )

      select start_time, 
           end_time, 
           array_agg(event_id) as event_ids, 
           array_agg(short_name) as short_names, 
           array_agg(in_count) as in_counts, 
           array_agg(out_count) as out_counts,
           array_agg(finished_in_count) as finished_in_counts,
           array_agg(finished_out_count) as finished_out_counts,
           sum(in_count) as total_in_count,
           sum(out_count) as total_out_count,
           sum(finished_in_count) as total_finished_in_count,
           sum(finished_out_count) as total_finished_out_count
      from ungrouped_results
      group by start_time, end_time
      order by start_time;
    SQL
  end

  # Includes the overall event group counts under the 'nil' key
  # @param [Integer, nil] event_id
  # @return [Counts]
  def counts_for_event(event_id)
    all_counts_by_event[event_id]
  end

  private

  # @return [Hash{Integer, nil => Counts}]
  def all_counts_by_event
    @all_counts_by_event ||=
      begin
        raw_data = event_ids.zip(short_names, in_counts, out_counts, finished_in_counts, finished_out_counts)
        counts_array = raw_data.map { |array| Counts.new(*array) }
        counts_array << overall_counts

        counts_array.index_by(&:event_id)
      end
  end

  # @return [Counts]
  def overall_counts
    Counts.new(nil, nil, total_in_count, total_out_count, total_finished_in_count, total_finished_out_count)
  end
end
