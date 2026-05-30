require "rails_helper"

RSpec.describe "PATCH /event_groups/:event_group_id/connect_service/:connect_service_id/field_mappings" do
  include Warden::Test::Helpers

  let(:user) { users(:admin_user) }
  let(:valid_params) do
    {
      field_mappings: {
        "0" => { source_question_id: "100", destination: "emergency_contact" },
        "1" => { source_question_id: "200", destination: "comments",
                 suppress_when: "No", value_when_present: "First Attempt" },
        "2" => { source_question_id: "300", destination: "comments" },
        "3" => { source_question_id: "999", destination: "" }, # don't sync — should be dropped
      },
    }
  end
  let(:event_group) { event_groups(:rufa_2017) }
  let(:race_connection) do
    Connection.find_by!(service_identifier: "runsignup", source_type: "Race", destination: event_group)
  end

  before { login_as user, scope: :user }
  after { Warden.test_reset! }

  it "writes the normalized mapping to the EventGroup-level Race Connection" do
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: valid_params

    race_connection.reload

    expected = [
      { "source_question_id" => 100, "destination" => "emergency_contact" },
      { "source_question_id" => 200, "destination" => "comments",
        "suppress_when" => "No", "value_when_present" => "First Attempt" },
      { "source_question_id" => 300, "destination" => "comments" },
    ]
    expect(race_connection.field_mappings).to eq(expected)
  end

  it "does not require any per-event Connection to exist" do
    event_group.events.each { |e| e.connections.from_service(:runsignup).destroy_all }
    event_level_count = event_group.events.flat_map { |e| e.connections.from_service(:runsignup).to_a }.size
    expect(event_level_count).to eq(0)

    expect do
      patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: valid_params
    end.not_to raise_error

    expect(race_connection.reload.field_mappings).not_to be_empty
  end

  it "coerces source_question_id strings into integers" do
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: valid_params

    race_connection.reload
    expect(race_connection.field_mappings.first["source_question_id"]).to eq(100)
  end

  it "drops rows whose destination is blank or unknown" do
    params = {
      field_mappings: {
        "0" => { source_question_id: "100", destination: "comments" },
        "1" => { source_question_id: "200", destination: "" },
        "2" => { source_question_id: "300", destination: "not_a_real_column" },
      },
    }
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: params

    race_connection.reload
    expect(race_connection.field_mappings.size).to eq(1)
    expect(race_connection.field_mappings.first["source_question_id"]).to eq(100)
  end

  it "omits empty suppress_when / value_when_present from the persisted mapping" do
    params = {
      field_mappings: {
        "0" => { source_question_id: "100", destination: "comments",
                 suppress_when: "", value_when_present: "" },
      },
    }
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: params

    race_connection.reload
    expect(race_connection.field_mappings.first.keys).to contain_exactly("source_question_id", "destination")
  end

  it "redirects back to the connect_service page on an HTML request" do
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: valid_params

    expect(response).to redirect_to(event_group_connect_service_path(event_group, "runsignup"))
  end

  it "renders a turbo_stream replace of the field_mappings_card on a turbo request" do
    allow_any_instance_of(ConnectServicePresenter).to receive(:race_questions).and_return([]) # rubocop:disable RSpec/AnyInstance
    turbo_headers = { "Accept" => "text/vnd.turbo-stream.html" }

    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: valid_params, headers: turbo_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream action=\"replace\"")
    expect(response.body).to include("field_mappings_card")
  end

  it "raises RecordNotFound when no Race Connection exists for the EventGroup" do
    race_connection.destroy!

    expect do
      patch event_group_connect_service_field_mappings_path(event_group, "runsignup"), params: valid_params
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises RecordNotFound for an unknown service_identifier" do
    expect do
      patch event_group_connect_service_field_mappings_path(event_group, "bogus"), params: valid_params
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
