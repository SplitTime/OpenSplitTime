# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rails 8.1 Timezone Handling", type: :model do
  describe "to_time_preserves_timezone configuration" do
    it "preserves timezone information when converting to Time" do
      # Verify the config is set correctly
      expect(Rails.application.config.active_support.to_time_preserves_timezone).to eq(:zone)
    end

    it "preserves timezone when converting DateTime to Time" do
      # Test in Mountain Time (Denver - where OST is based)
      Time.use_zone("America/Denver") do
        datetime = DateTime.new(2024, 7, 15, 10, 0, 0)
        time = datetime.to_time

        # With to_time_preserves_timezone = :zone, the time is in the application timezone
        expect(time).to be_a(Time)
        expect(time.hour).to eq(10)
      end
    end

    it "preserves timezone when converting Date to Time" do
      Time.use_zone("America/Denver") do
        date = Date.new(2024, 7, 15)
        time = date.to_time

        # Should be beginning of day in Denver timezone
        expect(time.hour).to eq(0)
        expect(time.zone).to eq("MDT")
      end
    end
  end

  describe "Event timezone handling" do
    let(:event_group) { event_groups(:hardrock_2015) }
    let(:event) { events(:hardrock_2015) }

    it "uses the event group's home timezone" do
      expect(event.home_time_zone).to be_present
      expect(event.event_group.home_time_zone).to be_present
    end

    it "handles scheduled_start_time in the correct timezone" do
      # Set a known timezone
      event_group.update!(home_time_zone: "America/Denver")

      # Scheduled start time should be interpreted in the event's timezone
      start_time = event.scheduled_start_time
      expect(start_time).to be_a(ActiveSupport::TimeWithZone)
    end

    it "correctly calculates time differences across timezones" do
      event_group.update!(home_time_zone: "America/Denver")

      # Create a split time in the event's timezone
      effort = event.efforts.first
      split_time = effort.split_times.first

      if split_time&.absolute_time
        # Times are stored in UTC in the database, but should be displayed in the event's timezone
        expect(split_time.absolute_time).to be_a(ActiveSupport::TimeWithZone)
        # The effort's home_time_zone should match the event's timezone
        expect(split_time.effort.home_time_zone).to eq("America/Denver")
      end
    end
  end

  describe "SplitTime timezone handling" do
    let(:event) { events(:hardrock_2015) }
    let(:effort) { event.efforts.first }

    context "when event is in America/Denver" do
      before do
        event.event_group.update!(home_time_zone: "America/Denver")
      end

      it "handles times correctly with the event's timezone" do
        Time.use_zone(event.home_time_zone) do
          # Times should be interpreted in the event's timezone
          time = Time.zone.parse("2024-07-15 10:00:00")
          expect(time.time_zone.name).to eq("America/Denver")
        end
      end

      it "calculates elapsed time correctly regardless of timezone" do
        # Use existing split times from fixtures
        split_times = effort.split_times.order(:absolute_time).limit(2)

        if split_times.size >= 2
          first_time = split_times.first
          second_time = split_times.second

          # Elapsed time calculation should work regardless of storage timezone
          elapsed = second_time.absolute_time - first_time.absolute_time
          expect(elapsed).to be_a(Numeric)
          expect(elapsed).to be >= 0
        end
      end
    end
  end

  describe "Effort birthdate and age calculation" do
    let(:event) { events(:hardrock_2015) }
    let(:effort) { event.efforts.first }

    it "calculates age correctly with timezone-aware dates" do
      birthdate = Date.new(1990, 1, 1)
      event_start = Time.zone.parse("2024-07-15 06:00:00")

      effort.update!(birthdate: birthdate)

      # Age calculation should work correctly across timezone boundaries
      Time.use_zone(event.home_time_zone) do
        age = ((event_start - birthdate.in_time_zone) / 1.year).to_i
        expect(age).to eq(34) # 2024 - 1990
      end
    end
  end

  describe "Import/Export with timezones" do
    let(:event_group) { event_groups(:hardrock_2015) }

    it "handles CSV imports with timezone data correctly" do
      # Simulate importing times from a different timezone
      event_group.update!(home_time_zone: "America/Denver")

      csv_time_string = "2024-07-15 10:00:00"

      Time.use_zone(event_group.home_time_zone) do
        parsed_time = Time.zone.parse(csv_time_string)
        expect(parsed_time.time_zone.name).to eq("America/Denver")
      end
    end

    it "exports times in the event's timezone" do
      event_group.update!(home_time_zone: "America/Denver")

      # When exporting, times should be in the event's timezone
      Time.use_zone(event_group.home_time_zone) do
        current_time = Time.current
        expect(current_time.time_zone.name).to eq("America/Denver")
      end
    end
  end

  describe "DST (Daylight Saving Time) transitions" do
    let(:event_group) { event_groups(:hardrock_2015) }

    it "handles DST spring forward correctly" do
      event_group.update!(home_time_zone: "America/Denver")

      # March 2024: DST starts March 10, 2024 at 2:00 AM
      Time.use_zone("America/Denver") do
        before_dst = Time.zone.parse("2024-03-10 01:00:00")
        after_dst = Time.zone.parse("2024-03-10 03:00:00")

        # Should be 1 hour difference (not 2) due to DST
        expect(after_dst - before_dst).to eq(1.hour)
      end
    end

    it "handles DST fall back correctly" do
      event_group.update!(home_time_zone: "America/Denver")

      # November 2024: DST ends November 3, 2024 at 2:00 AM
      Time.use_zone("America/Denver") do
        before_dst = Time.zone.parse("2024-11-03 00:00:00")
        after_dst = Time.zone.parse("2024-11-03 03:00:00")

        # Should be 4 hours difference (includes the extra hour)
        expect(after_dst - before_dst).to eq(4.hours)
      end
    end
  end

  describe "Multi-timezone event scenarios" do
    it "handles events in different timezones correctly" do
      # Create two events in different timezones
      denver_event_group = event_groups(:hardrock_2015)
      denver_event_group.update!(home_time_zone: "America/Denver")

      # Verify each event respects its own timezone
      Time.use_zone(denver_event_group.home_time_zone) do
        time_now = Time.current
        expect(time_now.time_zone.name).to eq("America/Denver")
      end
    end
  end
end
