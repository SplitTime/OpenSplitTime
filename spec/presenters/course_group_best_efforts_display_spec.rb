require "rails_helper"

RSpec.describe CourseGroupBestEffortsDisplay do
  subject { described_class.new(course_group, view_context) }

  let(:course_group) { course_groups(:both_directions) }
  let(:request) { instance_double(ActionDispatch::Request, params: {}) }
  let(:view_context) do
    double(prepared_params: ActionController::Parameters.new, request: request)
  end

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    setup_fixtures
    EffortSegment.set_all
  end

  after(:all) { EffortSegment.delete_all }
  # rubocop:enable RSpec/BeforeAfterAll

  describe "#filtered_segments" do
    it "does not issue a SELECT people query per segment" do
      segments = subject.filtered_segments

      person_queries = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        person_queries += 1 if payload[:sql] =~ /FROM "people"/
      end

      segments.each do |segment|
        segment.display_full_name
        segment.bio_historic
        segment.flexible_geolocation
      end

      expect(segments.size).to be > 1
      expect(person_queries).to eq(0)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end
  end
end
