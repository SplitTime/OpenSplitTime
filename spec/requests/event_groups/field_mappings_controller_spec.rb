require "rails_helper"

RSpec.describe "PATCH /event_groups/:event_group_id/connect_service/:service_identifier/field_mappings" do
  include Warden::Test::Helpers

  let(:user) { users(:admin_user) }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
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
  let(:event_1) { event_group.events.first }
  let(:event_2) { event_group.events.second }
  let!(:event_1_connection) do
    Connection.create!(service_identifier: :runsignup, source_type: "Event", source_id: "1001", destination: event_1)
  end
  let!(:event_2_connection) do
    Connection.create!(service_identifier: :runsignup, source_type: "Event", source_id: "1002", destination: event_2)
  end

  before { login_as user, scope: :user }
  after { Warden.test_reset! }

  it "writes the normalized mapping to every event-level Connection under the EventGroup" do
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: valid_params, headers: turbo_headers

    [event_1_connection, event_2_connection].each(&:reload)

    expected = [
      { "source_question_id" => 100, "destination" => "emergency_contact" },
      { "source_question_id" => 200, "destination" => "comments",
        "suppress_when" => "No", "value_when_present" => "First Attempt" },
      { "source_question_id" => 300, "destination" => "comments" },
    ]
    expect(event_1_connection.field_mappings).to eq(expected)
    expect(event_2_connection.field_mappings).to eq(expected)
  end

  it "coerces source_question_id strings into integers" do
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: valid_params, headers: turbo_headers

    event_1_connection.reload
    expect(event_1_connection.field_mappings.first["source_question_id"]).to eq(100)
  end

  it "drops rows whose destination is blank or unknown" do
    params = {
      field_mappings: {
        "0" => { source_question_id: "100", destination: "comments" },
        "1" => { source_question_id: "200", destination: "" },
        "2" => { source_question_id: "300", destination: "not_a_real_column" },
      },
    }
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: params, headers: turbo_headers

    event_1_connection.reload
    expect(event_1_connection.field_mappings.size).to eq(1)
    expect(event_1_connection.field_mappings.first["source_question_id"]).to eq(100)
  end

  it "omits empty suppress_when / value_when_present from the persisted mapping" do
    params = {
      field_mappings: {
        "0" => { source_question_id: "100", destination: "comments",
                 suppress_when: "", value_when_present: "" },
      },
    }
    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: params, headers: turbo_headers

    event_1_connection.reload
    expect(event_1_connection.field_mappings.first.keys).to contain_exactly("source_question_id", "destination")
  end

  it "renders the field_mappings_card turbo_stream replace" do
    allow_any_instance_of(ConnectServicePresenter).to receive(:race_questions).and_return([]) # rubocop:disable RSpec/AnyInstance

    patch event_group_connect_service_field_mappings_path(event_group, "runsignup"),
          params: valid_params, headers: turbo_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream action=\"replace\"")
    expect(response.body).to include("field_mappings_card")
  end

  it "raises RecordNotFound for an unknown service_identifier" do
    expect do
      patch event_group_connect_service_field_mappings_path(event_group, "bogus"),
            params: valid_params, headers: turbo_headers
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
