class OrganizationUsageIndexPresenter
  Row = Struct.new(:organization, :event_group_count, :event_count, :effort_count, :last_active_year)

  def for_profit_rows
    rows.reject { |row| row.organization.non_profit? }
  end

  def non_profit_rows
    rows.select { |row| row.organization.non_profit? }
  end

  private

  def rows
    @rows ||= Organization
              .joins(event_groups: { events: :efforts })
              .where(event_groups: { concealed: false }, efforts: { started: true })
              .group("organizations.id")
              .select(
                "organizations.*",
                "COUNT(DISTINCT event_groups.id)                          AS real_event_group_count",
                "COUNT(DISTINCT events.id)                                AS real_event_count",
                "COUNT(efforts.id)                                        AS real_effort_count",
                "MAX(EXTRACT(YEAR FROM events.scheduled_start_time))::int AS last_active_year",
              )
              .order(Arel.sql("COUNT(efforts.id) DESC"), :name)
              .map do |org|
      Row.new(
        organization: org,
        event_group_count: org.real_event_group_count,
        event_count: org.real_event_count,
        effort_count: org.real_effort_count,
        last_active_year: org.last_active_year,
      )
    end
  end
end
