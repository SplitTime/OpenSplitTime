require "rails_helper"

RSpec.describe FinishHistoryPresenter do
  subject { described_class.new(event: event, view_context: view_context) }

  let(:event) { events(:hardrock_2015) }
  let(:view_context) { double(prepared_params: ActionController::Parameters.new) }

  describe "#effort_rows" do
    it "does not issue a SELECT people query per row" do
      person_queries = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        person_queries += 1 if payload[:sql] =~ /FROM "people"/
      end

      rows = subject.effort_rows
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
end
