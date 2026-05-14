require "rails_helper"

RSpec.describe OrganizationUsageIndexPresenter do
  include ActiveSupport::Testing::TimeHelpers

  subject(:presenter) { described_class.new }

  # Fixture event years top out at 2017 — pin "today" to a date that keeps those
  # orgs within the 3-year activity window so the existing assertions stay valid.
  before { travel_to Date.new(2018, 6, 1) }

  describe "#for_profit_rows / #non_profit_rows" do
    it "places non_profit organizations only in non_profit_rows" do
      non_profit_org = organizations(:running_up_for_air)
      expect(non_profit_org).to be_non_profit

      expect(presenter.non_profit_rows.map { |row| row.organization.id }).to include(non_profit_org.id)
      expect(presenter.for_profit_rows.map { |row| row.organization.id }).not_to include(non_profit_org.id)
    end

    it "excludes organizations with no real efforts" do
      empty_org = Organization.create!(
        name: "Org With Nothing",
        created_by: users(:admin_user).id,
        concealed: false,
      )

      all_org_ids = (presenter.for_profit_rows + presenter.non_profit_rows).map { |row| row.organization.id }
      expect(all_org_ids).not_to include(empty_org.id)
    end

    it "excludes organizations whose only event groups are concealed" do
      hardrock = organizations(:hardrock)
      hardrock.event_groups.update_all(concealed: true)

      all_org_ids = (presenter.for_profit_rows + presenter.non_profit_rows).map { |row| row.organization.id }
      expect(all_org_ids).not_to include(hardrock.id)
    end

    it "sorts each section by effort count descending" do
      for_profit_counts = presenter.for_profit_rows.map(&:effort_count)
      non_profit_counts = presenter.non_profit_rows.map(&:effort_count)

      expect(for_profit_counts).to eq(for_profit_counts.sort.reverse)
      expect(non_profit_counts).to eq(non_profit_counts.sort.reverse)
    end

    it "counts only started efforts inside non-concealed event groups" do
      hardrock = organizations(:hardrock)
      total_started = Effort.joins(event: :event_group)
                            .where(event_groups: { organization_id: hardrock.id, concealed: false }, started: true)
                            .count

      row = presenter.for_profit_rows.find { |r| r.organization.id == hardrock.id }
      expect(row).not_to be_nil
      expect(row.effort_count).to eq(total_started)
    end

    it "exposes last_active_year as the most recent year of started efforts" do
      hardrock = organizations(:hardrock)
      expected_year = Event.joins(:event_group, :efforts)
                           .where(event_groups: { organization_id: hardrock.id, concealed: false }, efforts: { started: true })
                           .maximum("EXTRACT(YEAR FROM events.scheduled_start_time)")
                           .to_i

      row = presenter.for_profit_rows.find { |r| r.organization.id == hardrock.id }
      expect(row.last_active_year).to eq(expected_year)
    end

    it "exposes total_donated as the sum of monetary_donations amounts" do
      hardrock = organizations(:hardrock)
      expected_total = hardrock.monetary_donations.sum(:amount)

      row = presenter.for_profit_rows.find { |r| r.organization.id == hardrock.id }
      expect(row.total_donated).to eq(expected_total)
      expect(expected_total).to be > 0
    end

    it "returns zero total_donated for an org with no donations" do
      # rattlesnake_ramble has no fixture donations but no real efforts either,
      # so confirm via dirty_30_running which has efforts but no donations.
      dirty_30 = organizations(:dirty_30_running)
      row = presenter.for_profit_rows.find { |r| r.organization.id == dirty_30.id }

      expect(row).not_to be_nil
      expect(row.total_donated).to eq(0)
    end

    it "exposes last_donation_year as the most recent year of donations" do
      hardrock = organizations(:hardrock)
      expected_year = hardrock.monetary_donations.maximum(:received_on).year

      row = presenter.for_profit_rows.find { |r| r.organization.id == hardrock.id }
      expect(row.last_donation_year).to eq(expected_year)
    end

    it "drops organizations whose last event is more than 3 years ago" do
      hardrock = organizations(:hardrock) # last fixture event in 2016

      travel_to Date.new(2020, 1, 1) do
        # 2016 is exactly 4 years before 2020 — outside the 3-year window.
        all_org_ids = (presenter.for_profit_rows + presenter.non_profit_rows).map { |r| r.organization.id }
        expect(all_org_ids).not_to include(hardrock.id)
      end
    end

    it "keeps organizations whose last event is exactly 3 years ago" do
      hardrock = organizations(:hardrock) # last fixture event in 2016

      travel_to Date.new(2019, 1, 1) do
        # 2016 is exactly 3 years before 2019 — inside the window.
        all_org_ids = (presenter.for_profit_rows + presenter.non_profit_rows).map { |r| r.organization.id }
        expect(all_org_ids).to include(hardrock.id)
      end
    end
  end

  describe "#totals_for" do
    it "sums event_group_count, event_count, effort_count, and total_donated across the rows" do
      rows = presenter.for_profit_rows
      totals = presenter.totals_for(rows)

      expect(totals.event_group_count).to eq(rows.sum(&:event_group_count))
      expect(totals.event_count).to eq(rows.sum(&:event_count))
      expect(totals.effort_count).to eq(rows.sum(&:effort_count))
      expect(totals.total_donated).to eq(rows.sum { |r| r.total_donated.to_d })
    end

    it "returns zeros for an empty rows array" do
      totals = presenter.totals_for([])

      expect(totals.event_group_count).to eq(0)
      expect(totals.event_count).to eq(0)
      expect(totals.effort_count).to eq(0)
      expect(totals.total_donated).to eq(0)
    end
  end

  describe "Row#current_status" do
    include ActiveSupport::Testing::TimeHelpers

    def row(last_active:, last_donation:)
      described_class::Row.new(
        organization: nil,
        event_group_count: 0,
        event_count: 0,
        effort_count: 0,
        last_active_year: last_active,
        last_donation_year: last_donation,
        total_donated: 0,
      )
    end

    before { travel_to Date.new(2026, 6, 1) }

    it "returns nil when the org has no recent activity" do
      # 2024 is two years before "current" 2026 — not in current or prior year.
      expect(row(last_active: 2024, last_donation: 2024).current_status).to be_nil
      expect(row(last_active: nil, last_donation: nil).current_status).to be_nil
    end

    it "returns :paid when last donation matches the most recent event year" do
      expect(row(last_active: 2026, last_donation: 2026).current_status).to eq(:paid)
      expect(row(last_active: 2025, last_donation: 2025).current_status).to eq(:paid)
    end

    it "returns :recent when last donation is the year before the most recent event" do
      expect(row(last_active: 2026, last_donation: 2025).current_status).to eq(:recent)
      expect(row(last_active: 2025, last_donation: 2024).current_status).to eq(:recent)
    end

    it "returns :overdue when the org is active but donations are stale or missing" do
      expect(row(last_active: 2026, last_donation: 2023).current_status).to eq(:overdue)
      expect(row(last_active: 2026, last_donation: nil).current_status).to eq(:overdue)
      expect(row(last_active: 2025, last_donation: 2022).current_status).to eq(:overdue)
    end
  end
end
