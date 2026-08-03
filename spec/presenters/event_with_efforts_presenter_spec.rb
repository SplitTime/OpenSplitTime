require "rails_helper"

RSpec.describe EventWithEffortsPresenter do
  subject { described_class.new(event: event, params: prepared_params) }

  before { FactoryBot.reload }

  let(:event) { Event.new }
  let(:prepared_params) { create(:prepared_params) }

  describe "#initialize" do
    it "initializes given a PermittedParams object" do
      expect { subject }.not_to raise_error
    end

    it "raises an error if event argument is not given" do
      expect { described_class.new(params: prepared_params) }
        .to raise_error(ArgumentError, /missing keyword/)
    end

    it "raises an error if any unknown argument is given" do
      expect { described_class.new(event: event, params: prepared_params, random_param: 123) }
        .to raise_error(ArgumentError, /unknown keyword/)
    end
  end

  describe "#ranked_effort_rows" do
    let(:event) { events(:hardrock_2015) }
    let(:prepared_params) { build(:prepared_params, params: ActionController::Parameters.new({})) }

    it "attaches each effort's person without issuing a SELECT people query per row" do
      person_queries = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        person_queries += 1 if payload[:sql] =~ /FROM "people"/
      end

      rows = subject.ranked_effort_rows
      rows.each do |row|
        row.display_full_name
        row.bio_historic
        row.flexible_geolocation
      end

      expect(rows.size).to be > 1
      expect(person_queries).to be <= 1
      expect(rows).to all(satisfy { |row| row.effort.association(:person).loaded? && row.effort.person&.id == row.effort.person_id })
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end
  end

  describe "#sort_hash" do
    it "returns a hash containing sort data" do
      expect(subject.sort_hash).to eq({ "name" => :asc, "age" => :desc })
    end
  end

  describe "#sort_string" do
    it "returns a sort string in jsonapi format based on the sort_hash" do
      expect(subject.sort_string).to eq("name,-age")
    end
  end

  describe "#search_text" do
    it "returns a string containing search text" do
      expect(subject.search_text).to eq("jane")
    end
  end

  describe "#filter_hash" do
    it "returns a hash containing filter requirements" do
      expect(subject.filter_hash).to eq({ "state_code" => %w[NM NY BC], "gender" => [1] })
    end
  end
end
