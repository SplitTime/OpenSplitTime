class OrganizationUsageShowPresenter
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def total_event_groups
    real_event_groups_scope.distinct.count
  end

  def total_events
    Event
      .joins(:event_group, :efforts)
      .where(event_groups: { organization_id: organization.id, concealed: false }, efforts: { started: true })
      .distinct
      .count
  end

  def total_efforts
    breakdown.values.sum { |years| years.values.sum }
  end

  def chart_series
    breakdown.map do |(_course_id, course_name), years|
      { name: course_name, data: years.sort.to_h.transform_keys(&:to_s) }
    end
  end

  def course_rows
    breakdown.map do |(_course_id, course_name), years|
      { name: course_name, years: years.sort.to_h, total: years.values.sum }
    end
  end

  private

  def breakdown
    @breakdown ||= raw_counts.each_with_object({}) do |((course_id, course_name, year), count), acc|
      (acc[[course_id, course_name]] ||= {})[year.to_i] = count
    end
  end

  def raw_counts
    Effort
      .joins(event: [:event_group, :course])
      .where(event_groups: { organization_id: organization.id, concealed: false }, started: true)
      .group("courses.id", "courses.name", Arel.sql("EXTRACT(YEAR FROM events.scheduled_start_time)"))
      .count
  end

  def real_event_groups_scope
    EventGroup
      .joins(events: :efforts)
      .where(organization_id: organization.id, concealed: false, efforts: { started: true })
  end
end
