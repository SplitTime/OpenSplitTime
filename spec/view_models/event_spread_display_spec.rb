require "rails_helper"

RSpec.describe EventSpreadDisplay do
  subject { described_class.new(event: event, params: prepared_params) }

  let(:prepared_params) { ActionController::Parameters.new(display_style: "ampm") }

  describe "#effort_times_rows" do
    let(:event) { events(:hardrock_2015) }
    let(:prepared_params) { ActionController::Parameters.new(display_style: "elapsed") }

    it "does not issue a SELECT people query per row" do
      subject.send(:split_times)

      person_queries = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        person_queries += 1 if payload[:sql] =~ /FROM "people"/
      end

      rows = subject.effort_times_rows
      rows.each do |row|
        row.display_full_name
        row.bio_historic
        row.flexible_geolocation
      end

      expect(rows.size).to be > 1
      expect(person_queries).to be <= 1
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end
  end

  describe "#cache_key" do
    let(:event) { events(:hardrock_2015) }

    def presenter_with(raw_params)
      described_class.new(
        event: event,
        params: build(:prepared_params, params: ActionController::Parameters.new(raw_params)),
      )
    end

    it "is identical across requests that differ only by tracking params" do
      baseline = presenter_with(display_style: "elapsed").cache_key
      with_tracking = presenter_with(
        display_style: "elapsed",
        utm_source: "newsletter",
        fbclid: "abc123",
        _hsenc: "xyz",
      ).cache_key

      expect(with_tracking).to eq(baseline)
    end

    it "changes when display_style changes" do
      a = presenter_with(display_style: "elapsed").cache_key
      b = presenter_with(display_style: "ampm").cache_key

      expect(a).not_to eq(b)
    end

    it "changes when filter changes" do
      a = presenter_with(display_style: "elapsed", filter: { gender: "female" }).cache_key
      b = presenter_with(display_style: "elapsed", filter: { gender: "male" }).cache_key

      expect(a).not_to eq(b)
    end

    it "changes when sort changes" do
      a = presenter_with(display_style: "elapsed", sort: "name").cache_key
      b = presenter_with(display_style: "elapsed", sort: "-name").cache_key

      expect(a).not_to eq(b)
    end

    it "collapses unknown filter keys, unknown sort fields, and invalid display_style to the baseline" do
      baseline = presenter_with({}).cache_key
      junked = presenter_with(
        display_style: "banana",
        filter: { weirdkey: "foo" },
        sort: "-nonexistent",
      ).cache_key

      expect(junked).to eq(baseline)
    end
  end

  describe "#split_header_data" do
    let(:course) { build_stubbed(:course, name: "Testrock Counter-clockwise", splits: splits) }
    let(:event) { build_stubbed(:event, course: course, splits: splits) }
    let(:splits) { [split_1, split_2, split_3] }
    let(:split_1) { build_stubbed(:split, :start, base_name: "Starting Point") }
    let(:split_2) { build_stubbed(:split, base_name: "Aid Station 1", distance_from_start: 10_000) }
    let(:split_3) { build_stubbed(:split, :finish, base_name: "Finishing Point", distance_from_start: 20_000) }

    it "returns an array of hashes containing title, extensions, and distances" do
      expected = [
        { title: "Starting Point", extensions: [], distance: 0, split_name: "Starting Point", lap: 1 },
        { title: "Aid Station 1", extensions: %w[In Out], distance: 10_000, split_name: "Aid Station 1", lap: 1 },
        { title: "Finishing Point", extensions: [], distance: 20_000, split_name: "Finishing Point", lap: 1 }
      ]
      expect(subject.split_header_data).to eq(expected)
    end
  end

  describe "#display_style" do
    context "when display_style is provided in the params" do
      let(:prepared_params) { ActionController::Parameters.new(display_style: "ampm") }
      let(:event) { instance_double(Event, simple?: true, event_group: event_group) }
      let(:event_group) { instance_double(EventGroup, available_live: true) }

      it "returns the provided display_style" do
        expect(subject.display_style).to eq("ampm")
      end
    end

    context "when display_style is not provided in the params and the event has only start/finish splits" do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double(Event, simple?: true, event_group: event_group) }
      let(:event_group) { instance_double(EventGroup, available_live: true) }

      it "returns elapsed" do
        expect(subject.display_style).to eq("elapsed")
      end
    end

    context "when display_style is not provided in the params and the event has multiple splits and is available live" do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double(Event, simple?: false, event_group: event_group) }
      let(:event_group) { instance_double(EventGroup, available_live: true) }

      it "returns elapsed" do
        expect(subject.display_style).to eq("ampm")
      end
    end

    context "when display_style is not provided in the params and the event has multiple splits and is not available live" do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double(Event, simple?: false, event_group: event_group) }
      let(:event_group) { instance_double(EventGroup, available_live: false) }

      it "returns elapsed" do
        expect(subject.display_style).to eq("elapsed")
      end
    end
  end
end
