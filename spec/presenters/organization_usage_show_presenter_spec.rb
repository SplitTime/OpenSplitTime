require "rails_helper"

RSpec.describe OrganizationUsageShowPresenter do
  let(:hardrock) { organizations(:hardrock) }

  describe "#chart_series" do
    it "groups counts by course and year" do
      presenter = described_class.new(hardrock)

      expect(presenter.chart_series).not_to be_empty
      presenter.chart_series.each do |series|
        expect(series).to include(:name, :data)
        expect(series[:data]).not_to be_empty
        # Years are stringified so Chart.js treats the x-axis as discrete categories.
        series[:data].each_key { |year| expect(year).to match(/\A\d{4}\z/) }
      end
    end

    it "names each series after the course" do
      presenter = described_class.new(hardrock)
      course_names = hardrock.event_groups.flat_map { |eg| eg.events.map { |e| e.course.name } }.uniq

      expect(presenter.chart_series.pluck(:name)).to all(be_in(course_names))
    end

    it "combines multiple years of the same course into one series" do
      presenter = described_class.new(hardrock)

      # Hardrock CW course runs in both 2014 and 2016 under the same Course record
      multi_year_series = presenter.chart_series.find { |s| s[:data].values.count(&:positive?) >= 2 }
      expect(multi_year_series).not_to be_nil
    end

    it "aligns every series to the same sorted year axis" do
      presenter = described_class.new(hardrock)
      year_keys_per_series = presenter.chart_series.map { |s| s[:data].keys }

      expect(year_keys_per_series.uniq.size).to eq(1)
      years = year_keys_per_series.first
      expect(years).to eq(years.sort)
    end

    it "is empty when all event groups are concealed" do
      hardrock.event_groups.update_all(concealed: true)
      presenter = described_class.new(hardrock)

      expect(presenter.chart_series).to be_empty
      expect(presenter.total_efforts).to eq(0)
    end
  end

  describe "#sorted_years" do
    it "returns the sorted union of all years that have efforts" do
      presenter = described_class.new(hardrock)

      expect(presenter.sorted_years).to eq(presenter.sorted_years.sort.uniq)
      expect(presenter.sorted_years).to all(be_an(Integer))
    end
  end

  describe "#course_rows" do
    it "returns one row per course with a year_counts hash and a total" do
      presenter = described_class.new(hardrock)

      presenter.course_rows.each do |row|
        expect(row).to include(:name, :year_counts, :total)
        expect(row[:total]).to eq(row[:year_counts].values.sum)
      end
    end
  end

  describe "#total_efforts" do
    it "counts only started efforts" do
      Effort.joins(event: :event_group)
            .where(event_groups: { organization_id: hardrock.id })
            .update_all(started: false)
      presenter = described_class.new(hardrock)

      expect(presenter.total_efforts).to eq(0)
    end

    it "matches the sum of all chart data points" do
      presenter = described_class.new(hardrock)

      chart_sum = presenter.chart_series.sum { |series| series[:data].values.sum }
      expect(presenter.total_efforts).to eq(chart_sum)
    end
  end

  describe "#donations" do
    it "returns the org's monetary_donations sorted by received_on descending" do
      presenter = described_class.new(hardrock)

      expect(presenter.donations).to eq(hardrock.monetary_donations.order(received_on: :desc))
      expect(presenter.donations.map(&:received_on)).to eq(presenter.donations.map(&:received_on).sort.reverse)
    end

    it "is empty for an organization with no donations" do
      orphan_org = Organization.create!(name: "No Donations Org", created_by: users(:admin_user).id, concealed: false)
      presenter = described_class.new(orphan_org)

      expect(presenter.donations).to be_empty
    end
  end

  describe "#total_donated" do
    it "sums the donation amounts" do
      presenter = described_class.new(hardrock)
      expected = hardrock.monetary_donations.sum(:amount)

      expect(presenter.total_donated).to eq(expected)
      expect(expected).to be > 0
    end

    it "returns zero for an organization with no donations" do
      orphan_org = Organization.create!(name: "No Donations Org", created_by: users(:admin_user).id, concealed: false)
      presenter = described_class.new(orphan_org)

      expect(presenter.total_donated).to eq(0)
    end
  end
end
