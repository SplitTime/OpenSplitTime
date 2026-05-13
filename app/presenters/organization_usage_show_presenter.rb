class OrganizationUsageShowPresenter
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def total_event_groups
    breakdown.keys.size
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
    breakdown.map { |(_eg_id, eg_name), years| { name: eg_name, data: years.sort.to_h } }
  end

  def event_group_rows
    breakdown.map do |(_eg_id, eg_name), years|
      { name: eg_name, years: years.sort.to_h, total: years.values.sum }
    end
  end

  private

  def breakdown
    @breakdown ||= raw_counts.each_with_object({}) do |((eg_id, eg_name, year), count), acc|
      (acc[[eg_id, eg_name]] ||= {})[year.to_i] = count
    end
  end

  def raw_counts
    Effort
      .joins(event: :event_group)
      .where(event_groups: { organization_id: organization.id, concealed: false }, started: true)
      .group("event_groups.id", "event_groups.name", Arel.sql("EXTRACT(YEAR FROM events.scheduled_start_time)"))
      .count
  end
end
