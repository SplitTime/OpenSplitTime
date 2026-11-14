require "rails_helper"

RSpec.describe "Efforts start" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:effort) { efforts(:ggd30_50k_finished_second) }
  let(:start_time) { effort.starting_split_time.absolute_time }

  before { login_as admin_user, scope: :user }

  describe "PATCH start" do
    context "when the effort has later times but no start time" do
      before do
        effort.starting_split_time.destroy!
        effort.update_column(:data_status, :bad)
      end

      it "creates the start time and recomputes the effort's data status" do
        patch start_effort_path(effort),
              params: { actual_start_time: I18n.l(start_time.in_time_zone(effort.home_time_zone), format: :datetime_input) }

        effort.reload
        expect(effort.starting_split_time.absolute_time).to eq(start_time)
        expect(effort.data_status).to eq("good")
      end
    end
  end
end
