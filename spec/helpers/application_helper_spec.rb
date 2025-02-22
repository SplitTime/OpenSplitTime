require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#link_to" do
    context "when `disabled: true` is used" do
      it "adds the 'disabled' class and replaces href with '#'" do
        output = helper.link_to("Disabled Link", "/some_path", class: "btn", disabled: true)
        expect(output).to eq('<a class="btn disabled" href="#">Disabled Link</a>')
      end

      it "works with a block and modifies the correct argument" do
        output = helper.link_to("/some_path", class: "btn", disabled: true) do
          "Block Content"
        end
        expect(output).to eq('<a class="btn disabled" href="#">Block Content</a>')
      end
    end

    context "when `disabled: false` is used" do
      it "does not modify the class or href" do
        output = helper.link_to("Active Link", "/some_path", class: "btn", disabled: false)
        expect(output).to eq('<a class="btn" href="/some_path">Active Link</a>')
      end

      it "does not modify arguments when a block is given" do
        output = helper.link_to("/some_path", class: "btn", disabled: false) do
          "Block Content"
        end
        expect(output).to eq('<a class="btn" href="/some_path">Block Content</a>')
      end
    end

    context "when `disabled` is not specified" do
      it "renders a normal link without the 'disabled' class or href modification" do
        output = helper.link_to("Normal Link", "/some_path", class: "btn")
        expect(output).to eq('<a class="btn" href="/some_path">Normal Link</a>')
      end

      it "renders a normal link with a block without the 'disabled' class or href modification" do
        output = helper.link_to("/some_path", class: "btn") do
          "Block Content"
        end
        expect(output).to eq('<a class="btn" href="/some_path">Block Content</a>')
      end
    end
  end

  describe "time_format_hhmmss" do
    it "returns appropriate blanks when given a nil parameter" do
      expect(helper.time_format_hhmmss(nil)).to eq("--:--:--")
    end

    it "returns time in hh:mm:ss format" do
      expect(helper.time_format_hhmmss(3630)).to eq("01:00:30")
    end

    it "returns time in 00:mm:ss format when less than one hour" do
      expect(helper.time_format_hhmmss(620)).to eq("00:10:20")
    end

    it "works for times in excess of 24 hours" do
      expect(helper.time_format_hhmmss(100_000)).to eq("27:46:40")
    end
  end

  describe "time_format_hhmm" do
    it "returns appropriate blanks when given a nil parameter" do
      expect(helper.time_format_hhmm(nil)).to eq("--:--")
    end

    it "returns time in hh:mm format" do
      expect(helper.time_format_hhmm(3630)).to eq("01:00")
    end

    it "returns time in 00:mm format when less than one hour" do
      expect(helper.time_format_hhmm(620)).to eq("00:10")
    end

    it "works for times in excess of 24 hours" do
      expect(helper.time_format_hhmm(100_000)).to eq("27:46")
    end
  end

  describe "time_format_xxhyymzzs" do
    it "returns appropriate blanks when given a nil parameter" do
      expect(helper.time_format_xxhyymzzs(nil)).to eq("--:--:--")
    end

    it "returns time in xxhyymzzs format" do
      expect(helper.time_format_xxhyymzzs(3630)).to eq("01h00m30s")
    end

    it "returns time in yymzzs format when less than one hour" do
      expect(helper.time_format_xxhyymzzs(620)).to eq("10m20s")
    end

    it "works for times in excess of 24 hours" do
      expect(helper.time_format_xxhyymzzs(100_000)).to eq("27h46m40s")
    end
  end

  describe "time_format_xxhyym" do
    it "returns appropriate blanks when given a nil parameter" do
      expect(helper.time_format_xxhyym(nil)).to eq("--:--")
    end

    it "returns time in xxhyym format" do
      expect(helper.time_format_xxhyym(3630)).to eq("1h00m")
    end

    it "returns time in yym format when less than one hour" do
      expect(helper.time_format_xxhyym(620)).to eq("10m")
    end

    it "returns time in yym format when less than 10 minutes" do
      expect(helper.time_format_xxhyym(540)).to eq("9m")
    end

    it "works for times in excess of 24 hours" do
      expect(helper.time_format_xxhyym(100_000)).to eq("27h46m")
    end
  end

  describe "time_format_minutes" do
    it "returns appropriate blanks when given a nil parameter" do
      expect(helper.time_format_minutes(nil)).to eq("--")
    end

    it "returns time in xhym format when greater than 90 minutes" do
      expect(helper.time_format_minutes(7380)).to eq("2h03m")
    end

    it "returns time in yym format when less than 90 minutes" do
      expect(helper.time_format_minutes(4500)).to eq("75m")
    end

    it "returns time in ym format when less than 10 minutes" do
      expect(helper.time_format_minutes(540)).to eq("9m")
    end

    it "works for times in excess of 24 hours" do
      expect(helper.time_format_minutes(100_000)).to eq("27h46m")
    end
  end

  describe "lat/lon_format" do
    it "returns [Unknown] for latitude or longitude that is not provided" do
      expect(helper.latlon_format(nil, nil)).to eq("[Unknown] / [Unknown]")
    end

    it "returns latitude north for positive latitude" do
      expect(helper.latlon_format(40.5, nil)).to eq("40.5°N / [Unknown]")
    end

    it "returns latitude south for negative latitude" do
      expect(helper.latlon_format(-35.95, nil)).to eq("35.95°S / [Unknown]")
    end

    it "returns longitude east for positive longitude" do
      expect(helper.latlon_format(nil, 101.1)).to eq("[Unknown] / 101.1°E")
    end

    it "returns longitude west for negative longitude" do
      expect(helper.latlon_format(nil, -115.0)).to eq("[Unknown] / 115.0°W")
    end

    it "returns a correct latitude and longitude when both values are given" do
      expect(helper.latlon_format(44.4, -20.5)).to eq("44.4°N / 20.5°W")
    end
  end
end
