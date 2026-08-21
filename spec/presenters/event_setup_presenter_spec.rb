require "rails_helper"

RSpec.describe EventSetupPresenter do
  subject { described_class.new(event, view_context) }

  let(:event) { events(:hardrock_2016) }
  let(:view_context) do
    double("view_context", # rubocop:disable RSpec/VerifiedDoubles
           params: {},
           current_user: users(:admin_user))
  end

  describe "#courses_for_select" do
    let(:option_ids) { subject.courses_for_select.map(&:second) }

    context "when the event's course belongs to the event group's organization" do
      it "lists the organization's courses with a create-new option" do
        expect(option_ids).to include(event.course_id)
        expect(option_ids.first).to be_nil
      end
    end

    context "when the event's course belongs to another organization" do
      let(:foreign_course) { courses(:d30_12m_course) }

      before { event.update_column(:course_id, foreign_course.id) }

      it "includes the event's course so the selector does not blank the course_id" do
        expect(option_ids).to include(foreign_course.id)
      end
    end
  end
end
