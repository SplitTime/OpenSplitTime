class OrganizationUsageIndexPresenter
  Row = Struct.new(:organization, :event_group_count, :event_count, :effort_count, :last_active_year,
                   :last_donation_year, :total_donated) do
    # Returns:
    #   nil       — org isn't active (no real events in the prior or current year)
    #   :paid     — donated in the same year as the most recent event, or any year since
    #   :recent   — donated in the year before the most recent event
    #   :overdue  — active but donation history is older than that, or nonexistent
    def current_status
      current_year = Date.current.year
      return nil if last_active_year.nil? || last_active_year < current_year - 1
      return :overdue if last_donation_year.nil?
      return :paid if last_donation_year >= last_active_year
      return :recent if last_donation_year == last_active_year - 1

      :overdue
    end
  end

  Totals = Struct.new(:event_group_count, :event_count, :effort_count, :total_donated)

  # Correlated subqueries rather than joining monetary_donations into the main aggregate —
  # joining would multiply the effort counts by the donation row count.
  TOTAL_DONATED_SQL = <<~SQL.squish.freeze
    (
      SELECT COALESCE(SUM(monetary_donations.amount), 0)
      FROM monetary_donations
      WHERE monetary_donations.organization_id = organizations.id
    ) AS total_donated
  SQL

  LAST_DONATION_YEAR_SQL = <<~SQL.squish.freeze
    (
      SELECT MAX(EXTRACT(YEAR FROM monetary_donations.received_on))::int
      FROM monetary_donations
      WHERE monetary_donations.organization_id = organizations.id
    ) AS last_donation_year
  SQL

  # Orgs whose last real event was more than ACTIVE_WITHIN_YEARS years ago are dropped
  # — donation outreach for long-dormant orgs isn't actionable.
  ACTIVE_WITHIN_YEARS = 3

  def for_profit_rows
    rows.reject { |row| row.organization.non_profit? }
  end

  def non_profit_rows
    rows.select { |row| row.organization.non_profit? }
  end

  def totals_for(rows)
    Totals.new(
      event_group_count: rows.sum(&:event_group_count),
      event_count: rows.sum(&:event_count),
      effort_count: rows.sum(&:effort_count),
      total_donated: rows.sum { |row| row.total_donated.to_d },
    )
  end

  private

  def rows
    cutoff_year = Date.current.year - ACTIVE_WITHIN_YEARS
    @rows ||= Organization
              .joins(event_groups: { events: :efforts })
              .where(event_groups: { concealed: false }, efforts: { started: true })
              .group("organizations.id")
              .having("MAX(EXTRACT(YEAR FROM events.scheduled_start_time)) >= ?", cutoff_year)
              .select(
                "organizations.*",
                "COUNT(DISTINCT event_groups.id)                          AS real_event_group_count",
                "COUNT(DISTINCT events.id)                                AS real_event_count",
                "COUNT(efforts.id)                                        AS real_effort_count",
                "MAX(EXTRACT(YEAR FROM events.scheduled_start_time))::int AS last_active_year",
                TOTAL_DONATED_SQL,
                LAST_DONATION_YEAR_SQL,
              )
              .order(Arel.sql("COUNT(efforts.id) DESC"), :name)
              .map do |org|
      Row.new(
        organization: org,
        event_group_count: org.real_event_group_count,
        event_count: org.real_event_count,
        effort_count: org.real_effort_count,
        last_active_year: org.last_active_year,
        last_donation_year: org.last_donation_year,
        total_donated: org.total_donated,
      )
    end
  end
end
