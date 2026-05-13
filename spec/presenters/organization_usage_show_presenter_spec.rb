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
end
