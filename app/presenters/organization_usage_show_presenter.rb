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

  def sorted_years
    @sorted_years ||= breakdown.values.flat_map(&:keys).uniq.sort
  end

  def chart_series
    breakdown.map do |(_course_id, course_name), years|
      data = sorted_years.to_h { |year| [year.to_s, years.fetch(year, 0)] }
      { name: course_name, data: data }
    end
  end

  def course_rows
    breakdown.map do |(_course_id, course_name), years|
      { name: course_name, year_counts: years, total: years.values.sum }
    end
  end

  def donations
    @donations ||= organization.monetary_donations.order(received_on: :desc)
  end

  def total_donated
    donations.sum(:amount)
  end

  def first_donation_year
    donations.minimum(:received_on)&.year
  end

  def last_donation_year
    donations.maximum(:received_on)&.year
  end

  # Chart data keyed by stringified year so Chart.js treats the x-axis as discrete
  # categories (same trick as #chart_series). Spans the full range from the org's
  # first real event year to the current year, filling years without donations with 0
  # so the chart shows a continuous timeline rather than skipping over quiet years.
  def donations_by_year
    start_year = sorted_years.first || first_donation_year
    return {} if start_year.nil?

    amounts = organization.monetary_donations
                          .group(Arel.sql("EXTRACT(YEAR FROM received_on)::int"))
                          .sum(:amount)
    (start_year..Date.current.year).to_h { |year| [year.to_s, amounts[year] || 0] }
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
