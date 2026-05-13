require "rails_helper"

RSpec.describe OrganizationUsageIndexPresenter do
  subject(:presenter) { described_class.new }

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
  end
end
