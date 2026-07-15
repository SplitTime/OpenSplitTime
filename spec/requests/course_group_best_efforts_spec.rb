require "rails_helper"
require "csv"

RSpec.describe "CourseGroupBestEfforts" do
  include ActiveJob::TestHelper
  include Warden::Test::Helpers

  let(:course_group) { course_groups(:both_directions) }
  let(:organization) { course_group.organization }
  let(:user) { users(:admin_user) }

  # Populate the effort_segments the best_effort_segments view reads from, so the export has real rows.
  before { EffortSegment.set_all }
  after { Warden.test_reset! }

  describe "POST /organizations/:organization_id/course_groups/:course_group_id/best_efforts/export_async" do
    subject(:make_request) do
      post export_async_organization_course_group_best_efforts_path(organization, course_group),
           headers: { "HTTP_REFERER" => organization_course_group_best_efforts_url(organization, course_group) }
    end

    before { login_as user, scope: :user }

    it "runs the async export end to end and writes a CSV with every configured attribute" do
      expect { perform_enqueued_jobs { make_request } }.to change(user.export_jobs, :count).by(1)

      export_job = user.export_jobs.last
      expect(export_job).to be_finished
      expect(export_job.file).to be_attached

      csv = CSV.parse(export_job.file.download, headers: true)
      expected_headers = BestEffortSegmentParameters.csv_export_attributes.map(&:humanize)

      # Serializing a real segment exercises every attribute — "Place" is the one that regressed (#2157).
      expect(csv.headers).to match_array(expected_headers)
      expect(csv.size).to be_positive
      expect(csv.first.fetch("Place")).to be_present
    end
  end
end
