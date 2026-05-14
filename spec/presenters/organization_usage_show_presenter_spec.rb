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

  describe "donations" do
    let(:presenter) { described_class.new(hardrock) }

    it "returns the org's monetary_donations newest first" do
      expect(presenter.donations).to eq(hardrock.monetary_donations.order(received_on: :desc))
    end

    it "totals the donation amounts" do
      expect(presenter.total_donated).to eq(hardrock.monetary_donations.sum(:amount))
      expect(presenter.total_donated).to be > 0
    end

    it "exposes the donation year range" do
      expect(presenter.first_donation_year).to eq(hardrock.monetary_donations.minimum(:received_on).year)
      expect(presenter.last_donation_year).to eq(hardrock.monetary_donations.maximum(:received_on).year)
    end

    it "returns nil donation years when the org has none" do
      orphan = Organization.create!(name: "No Donations Org", created_by: users(:admin_user).id, concealed: false)
      empty_presenter = described_class.new(orphan)

      expect(empty_presenter.first_donation_year).to be_nil
      expect(empty_presenter.last_donation_year).to be_nil
      expect(empty_presenter.total_donated).to eq(0)
      expect(empty_presenter.donations_by_year).to be_empty
    end
  end

  describe "#donations_by_year" do
    let(:presenter) { described_class.new(hardrock) }

    it "buckets donation amounts by stringified year, sorted ascending" do
      data = presenter.donations_by_year

      expect(data).not_to be_empty
      expect(data.keys).to all(match(/\A\d{4}\z/))
      expect(data.keys).to eq(data.keys.sort)
    end

    it "sums donations within the same year" do
      hardrock.monetary_donations.create!(received_on: Date.new(2024, 9, 12), amount: 100, source: "paypal")
      hardrock.monetary_donations.create!(received_on: Date.new(2024, 11, 30), amount: 50, source: "paypal")

      expect(presenter.donations_by_year["2024"]).to eq(hardrock.monetary_donations.where("EXTRACT(YEAR FROM received_on) = 2024").sum(:amount))
    end
  end
end
