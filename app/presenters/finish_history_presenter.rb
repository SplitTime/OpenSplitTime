class FinishHistoryPresenter < BasePresenter
  attr_reader :event

  delegate :name, :course, :course_name, :organization, :organization_name, :to_param, :multiple_laps?,
           :event_group, :ordered_events_within_group, :results_template, :scheduled_start_time_local, to: :event
  delegate :available_live, :multiple_events?, to: :event_group
  delegate :course_groups, to: :course

  def initialize(event:, view_context:)
    @event = event
    @params = view_context.prepared_params
  end

  def effort_rows
    @effort_rows ||= efforts.map { |effort| EffortRow.new(effort) }
  end

  def history_for(row)
    indexed_finish_histories[row.person_id] || FinishHistory.new
  end

  # @return [Hash, Enumerator]
  def indexed_finish_histories
    @indexed_finish_histories ||= finish_histories.index_by(&:person_id)
  end

  private

  attr_reader :template, :params

  def efforts
    @efforts ||= event.efforts.ranking_subquery
  end

  # @return [Array<FinishHistory>]
  def finish_histories
    FinishHistory.execute_query(event_id: event.id)
  end
end
