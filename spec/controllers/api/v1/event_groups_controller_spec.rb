require "rails_helper"

RSpec.describe Api::V1::EventGroupsController do
  include BitkeyDefinitions

  let(:event_group) { event_groups(:dirty_30) }
  let(:type) { "event_groups" }

  describe "#index" do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

    via_login_and_jwt do
      it "returns a successful 200 response" do
        make_request
        expect(response.status).to eq(200)
      end

      it "returns each event_group" do
        make_request
        expect(response.status).to eq(200)
        expect(EventGroup.count).to eq(8)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["data"].size).to eq(8)
        expect(parsed_response["data"].map { |item| item["id"].to_i }).to eq(EventGroup.all.map(&:id))
      end

      context "when a sort parameter is provided" do
        let(:params) { { sort: "name" } }

        it "sorts properly in ascending order based on the parameter" do
          make_request
          parsed_response = JSON.parse(response.body)
          names = parsed_response["data"].map { |item| item.dig("attributes", "name") }
          expect(names.first).to eq("Dirty 30")
          expect(names.last).to eq("SUM")
        end
      end

      context "when a negative sort parameter is provided" do
        let(:params) { { sort: "-name" } }

        it "sorts properly in descending order based on the parameter" do
          make_request
          parsed_response = JSON.parse(response.body)
          names = parsed_response["data"].map { |item| item.dig("attributes", "name") }
          expect(names.first).to eq("SUM")
          expect(names.last).to eq("Dirty 30")
        end
      end

      context "when multiple sort parameters are provided" do
        let(:params) { { sort: "available_live,name" } }

        it "sorts properly on multiple fields" do
          make_request
          parsed_response = JSON.parse(response.body)
          names = parsed_response["data"].map { |item| item.dig("attributes", "name") }
          expect(names.first).to eq("Hardrock 2014")
          expect(names.last).to eq("SUM")
        end
      end

      context "when a filter[:available_live] param is given" do
        let(:params) { { filter: { available_live: true } } }

        it "returns only those event_groups that are available live" do
          get :index, params: params

          expect(response.status).to eq(200)
          expected = ["Dirty 30", "Hardrock 2015", "Hardrock 2016", "RUFA 2017", "SUM"]
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["data"].size).to eq(5)
          expect(parsed_response["data"].map { |item| item.dig("attributes", "name") }).to match_array(expected)
        end
      end
    end
  end

  describe "#show" do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context "when an existing event_group.id is provided" do
        let(:params) { { id: event_group } }
        let(:data_entry_groups) do
          [
            {
              "title" => "Start/Finish",
              "entries" => [
                {
                  "subSplitKind" => "in",
                  "label" => "Start",
                  "splitName" => "Start",
                  "parameterizedSplitName" => "start"
                },
                {
                  "subSplitKind" => "in",
                  "label" => "Finish",
                  "splitName" => "Finish",
                  "parameterizedSplitName" => "finish"
                }
              ]
            },
            {
              "title" => "Aid #1/Aid #4",
              "entries" => [
                {
                  "subSplitKind" => "in",
                  "label" => "Aid #1",
                  "splitName" => "Aid #1",
                  "parameterizedSplitName" => "aid-1"
                },
                {
                  "subSplitKind" => "in",
                  "label" => "Aid #4",
                  "splitName" => "Aid #4",
                  "parameterizedSplitName" => "aid-4"
                }
              ]
            },
            {
              "title" => "Aid #2",
              "entries" => [
                {
                  "subSplitKind" => "in",
                  "label" => "Aid #2",
                  "splitName" => "Aid #2",
                  "parameterizedSplitName" => "aid-2"
                }
              ]
            },
            {
              "title" => "Aid #3",
              "entries" => [
                {
                  "subSplitKind" => "in",
                  "label" => "Aid #3",
                  "splitName" => "Aid #3",
                  "parameterizedSplitName" => "aid-3"
                }
              ]
            },
            {
              "title" => "Aid #5",
              "entries" => [
                {
                  "subSplitKind" => "in",
                  "label" => "Aid #5",
                  "splitName" => "Aid #5",
                  "parameterizedSplitName" => "aid-5"
                }
              ]
            }
          ]
        end

        it "returns a successful 200 response" do
          make_request
          expect(response.status).to eq(200)
        end

        it "returns data of a single event_group" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["data"]["id"].to_i).to eq(event_group.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end

        it "includes a dataEntryGroups key containing information mapping aid station names to relevant data entry information" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["data"]["attributes"]["dataEntryGroups"].first).to eq(data_entry_groups.first)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context "if the event_group does not exist" do
        let(:params) { { id: 0 } }

        it "returns an error" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["errors"]).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#create" do
    subject(:make_request) { post :create, params: params }
    let(:organization) { organizations(:hardrock) }
    let(:home_time_zone) { "Arizona" }

    via_login_and_jwt do
      context "when provided data is valid" do
        let(:params) { { data: { type: type, attributes: { name: "Test Event Group", organization_id: organization.id, home_time_zone: home_time_zone } } } }

        it "returns a successful json response" do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["data"]["id"]).not_to be_nil
          expect(response.status).to eq(201)
        end

        it "creates an event_group record" do
          expect { make_request }.to change { EventGroup.count }.by(1)
        end
      end
    end
  end

  describe "#update" do
    subject(:make_request) { put :update, params: params }
    let(:params) { { id: event_group_id, data: { type: type, attributes: attributes } } }
    let(:attributes) { { name: "Updated EventGroup Name" } }

    via_login_and_jwt do
      context "when the event_group exists" do
        let(:event_group_id) { event_group.id }

        it "returns a successful json response" do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it "updates the specified fields" do
          make_request
          event_group.reload
          expect(event_group.name).to eq(attributes[:name])
        end
      end

      context "when the event_group does not exist" do
        let(:event_group_id) { 0 }

        it "returns an error" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["errors"]).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#destroy" do
    subject(:make_request) { delete :destroy, params: { id: event_group_id } }

    via_login_and_jwt do
      context "when the record exists" do
        let!(:event_group) { create(:event_group) }
        let(:event_group_id) { event_group.id }

        it "returns a successful json response" do
          make_request
          expect(response.status).to eq(200)
        end

        it "destroys the event_group record" do
          expect { make_request }.to change { EventGroup.count }.by(-1)
        end
      end

      context "when the record does not exist" do
        let(:event_group_id) { 0 }

        it "returns an error if the event_group does not exist" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["errors"]).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#import" do
    subject(:make_request) { post :import, params: request_params }

    let(:course) { courses(:hardrock_cw) }
    let(:ordered_splits) { course.ordered_splits }
    let(:event_group) { event.event_group }
    let(:event) { events(:hardrock_2016) }
    let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
    let(:entered_time_in) { time_zone.parse("2016-07-15 17:00:00") }
    let(:entered_time_out) { time_zone.parse("2016-07-15 17:20:00") }
    let(:effort) { efforts(:hardrock_2016_start_only) }
    let(:bib_number) { effort.bib_number.to_s }
    let(:strict) { nil }
    let(:unique_key) { nil }
    let(:limited_response) { nil }

    context "when provided with an array of raw_time hashes and data_format: :jsonapi_batch" do
      let(:split_name) { ordered_splits.second.base_name }
      let(:request_params) { { id: event_group.id, data_format: "jsonapi_batch", data: data, strict: strict, unique_key: unique_key, limited_response: limited_response } }
      let(:data) do
        [
          { type: "raw_time",
            attributes: { bibNumber: bib_number, splitName: split_name, subSplitKind: "in", enteredTime: entered_time_in,
                          withPacer: "true", stoppedHere: "false", source: source } },
          { type: "raw_time",
            attributes: { bibNumber: bib_number, splitName: split_name, subSplitKind: "out", enteredTime: entered_time_out,
                          withPacer: "true", stoppedHere: "true", source: source } }
        ]
      end
      let(:source) { "ost-remote-1234" }

      context "when raw_time data is valid" do
        via_login_and_jwt do
          it "creates raw_times" do
            expect { make_request }.to change { RawTime.count }.by(2)
            raw_times = RawTime.last(2)

            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["data"].map { |record| record["type"] }).to all eq("rawTimes")
            expect(raw_times.map(&:bib_number)).to all eq(bib_number)
            expect(raw_times.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(raw_times.map(&:entered_time).map(&:to_datetime)).to eq([entered_time_in, entered_time_out])
            expect(raw_times.map(&:event_group_id)).to all eq(event_group.id)
          end

          it "invokes a job to process imported raw times" do
            allow(ProcessImportedRawTimesJob).to receive(:perform_later) do |_, raw_times|
              raw_times.sort_by!(&:id)
            end

            make_request
            raw_times = RawTime.last(2)

            expect(ProcessImportedRawTimesJob).to have_received(:perform_later).with(event_group, raw_times.sort_by(&:id))
          end
        end
      end

      context "when raw_times include leading zeros" do
        via_login_and_jwt do
          let(:data) do
            [
              { type: "raw_time",
                attributes: { bibNumber: bib_number_leading_zeros, splitName: split_name, subSplitKind: "in", enteredTime: entered_time_in,
                              withPacer: "true", stoppedHere: "false", source: source } },
              { type: "raw_time",
                attributes: { bibNumber: bib_number_leading_zeros, splitName: split_name, subSplitKind: "out", enteredTime: entered_time_out,
                              withPacer: "true", stoppedHere: "true", source: source } }
            ]
          end
          let(:bib_number_leading_zeros) { "00#{bib_number}" }

          it "creates_raw_times" do
            expect { make_request }.to change { RawTime.count }.by(2)
            raw_times = RawTime.last(2)

            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["data"].map { |record| record["type"] }).to all eq("rawTimes")
            expect(raw_times.map(&:bib_number)).to all eq(bib_number_leading_zeros)
            expect(raw_times.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(raw_times.map { |rt| rt.entered_time.to_datetime }).to eq([entered_time_in, entered_time_out])
            expect(raw_times.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context "when one raw_time is valid and another raw_time is invalid" do
        via_login_and_jwt do
          let(:data) do
            [
              { type: "raw_time",
                attributes: { bibNumber: nil, splitName: split_name, subSplitKind: "in", enteredTime: entered_time_in,
                              withPacer: "true", stoppedHere: "false", source: source } },
              { type: "raw_time",
                attributes: { bibNumber: bib_number, splitName: split_name, subSplitKind: "out", enteredTime: entered_time_out,
                              withPacer: "true", stoppedHere: "true", source: source } }
            ]
          end

          it "does not create any raw_times and returns 422" do
            expect { make_request }.to change { RawTime.count }.by(0)
            expect(response.status).to eq(422)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["errors"].first.dig("detail", "messages")).to include("Bib number can't be blank")
          end
        end
      end

      context 'when params[:strict] is "true"' do
        via_login_and_jwt do
          let(:strict) { true }

          it "creates raw_times and returns 201" do
            expect { make_request }.to change { RawTime.count }.by(2)
            raw_times = RawTime.last(2)

            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["data"].map { |record| record["type"] }).to all(eq("rawTimes"))
            expect(raw_times.size).to eq(2)
            expect(raw_times.map(&:bib_number)).to all eq(bib_number)
            expect(raw_times.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(raw_times.map { |rt| rt.entered_time.to_datetime }).to eq([entered_time_in, entered_time_out])
            expect(raw_times.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context 'when params[:limited_response] is "true"' do
        via_login_and_jwt do
          let(:limited_response) { true }

          it "creates raw_times and returns 201 without sending other data" do
            expect { make_request }.to change { RawTime.count }.by(2)
            raw_times = RawTime.last(2)

            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response).to eq({})
            expect(raw_times.size).to eq(2)
            expect(raw_times.map(&:bib_number)).to all eq(bib_number)
            expect(raw_times.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(raw_times.map { |rt| rt.entered_time.to_datetime }).to eq([entered_time_in, entered_time_out])
            expect(raw_times.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context "when there is a duplicate raw_time in the database" do
        before do
          create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, bitkey: in_bitkey,
                 entered_time: entered_time_in, with_pacer: true, stopped_here: false, source: source)
        end

        context "when unique_key is set" do
          via_login_and_jwt do
            let(:unique_key) { %w[enteredTime splitName bitkey bibNumber source withPacer stoppedHere] }

            it "saves the non-duplicate raw_time to the database and updates the duplicate raw_time" do
              expect { make_request }.to change { RawTime.count }.by(1)

              expect(response.status).to eq(201)
            end
          end
        end

        context "when unique_key is not set" do
          via_login_and_jwt do
            let(:unique_key) { nil }

            it "saves both raw_times to the database" do
              expect { make_request }.to change { RawTime.count }.by(2)
              expect(response.status).to eq(201)
            end
          end
        end
      end
    end
  end

  describe "#pull_raw_times" do
    subject(:make_request) { patch :pull_raw_times, params: request_params }
    let(:request_params) { { id: event_group.id } }

    let(:event_group) { event_groups(:hardrock_2016) }
    let(:event) { events(:hardrock_2016) }
    let!(:effort_1) { efforts(:hardrock_2016_progress_sherman) }
    let!(:effort_2) { efforts(:hardrock_2016_dropped_grouse) }
    let!(:start_split) { event.ordered_splits.first }
    let!(:aid_split) { event.ordered_splits.second }
    let!(:finish_split) { event.ordered_splits.last }
    let!(:effort_1_split_time_1) { split_times(:hardrock_2016_progress_sherman_start_1) }
    let!(:effort_1_split_time_2) { split_times(:hardrock_2016_progress_sherman_telluride_in_1) }

    let(:current_user) { controller.current_user }

    context "when unreviewed raw_times are available" do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, effort: effort_1, bib_number: effort_1.bib_number, entered_time: "2017-07-01 11:22:33-0600", split_name: "Finish") }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, effort: effort_2, bib_number: effort_2.bib_number, entered_time: "2017-07-01 12:23:34-0600", split_name: "Finish") }

      via_login_and_jwt do
        it "marks the raw_times as having been reviewed and returns raw_time_rows with entered_times" do
          response = make_request
          expect(RawTime.last(2).pluck(:reviewed_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig("data", "rawTimeRows")

          expect(time_rows.size).to eq(2)
          expect(time_rows.map { |row| row["rawTimes"].size }).to match_array([1, 1])
          expect(time_rows.map { |row| row["rawTimes"].first["splitName"] }).to all eq(finish_split.base_name)
          expect(time_rows.map { |row| row["rawTimes"].first["bibNumber"] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
          expect(time_rows.map { |row| row["rawTimes"].first["enteredTime"] }).to match_array(["2017-07-01 11:22:33-0600", "2017-07-01 12:23:34-0600"])
        end
      end
    end

    context "when unreviewed raw_times have in and out times that can be paired" do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: "112", absolute_time: "2017-07-01 11:22:33", split_name: "Telluride", sub_split_kind: "in") }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: "112", absolute_time: "2017-07-01 12:23:34", split_name: "Telluride", sub_split_kind: "out") }

      via_login_and_jwt do
        it "marks the raw_times as having been reviewed and returns them in a single raw_time_row" do
          response = make_request
          expect(RawTime.last(2).pluck(:reviewed_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig("data", "rawTimeRows")

          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row["rawTimes"].size).to eq(2)
          expect(time_row["rawTimes"].map { |rt| rt["splitName"] }).to match_array([aid_split.base_name, aid_split.base_name])
          expect(time_row["rawTimes"].map { |rt| rt["bibNumber"] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context "when unreviewed raw_times do not match existing bib numbers" do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: "999", absolute_time: "2017-07-01 11:22:33", split_name: "Telluride", sub_split_kind: "in") }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: "999", absolute_time: "2017-07-01 12:23:34", split_name: "Telluride", sub_split_kind: "out") }

      via_login_and_jwt do
        it "marks the raw_times as having been reviewed and returns a raw_time_row with event and effort attributes set to nil" do
          response = make_request
          expect(RawTime.last(2).pluck(:reviewed_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig("data", "rawTimeRows")
          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row["rawTimes"].size).to eq(2)
          expect(time_row["rawTimes"].map { |rt| rt["splitName"] }).to match_array([aid_split.base_name, aid_split.base_name])
          expect(time_row["rawTimes"].map { |rt| rt["bibNumber"] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context "when unreviewed raw_times do not match existing split names" do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: "111", absolute_time: "2017-07-01 11:22:33", split_name: "Nonexistent", sub_split_kind: "in") }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: "111", absolute_time: "2017-07-01 12:23:34", split_name: "Nonexistent", sub_split_kind: "out") }

      via_login_and_jwt do
        it "marks the raw_times as having been reviewed and returns a raw_time_row with event and effort attributes loaded" do
          response = make_request
          expect(RawTime.last(2).pluck(:reviewed_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig("data", "rawTimeRows")
          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row["rawTimes"].size).to eq(2)
          expect(time_row["rawTimes"].map { |rt| rt["splitName"] }).to match_array([raw_time_1.split_name, raw_time_2.split_name])
          expect(time_row["rawTimes"].map { |rt| rt["bibNumber"] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context "when no unreviewed raw_times are available" do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: "111", absolute_time: "2017-07-01 11:22:33", split_name: "Finish", reviewed_by: 1, reviewed_at: Time.now) }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: "112", absolute_time: "2017-07-01 12:23:34", split_name: "Finish", reviewed_by: 1, reviewed_at: Time.now) }

      via_login_and_jwt do
        it "returns an empty array" do
          response = make_request
          result = JSON.parse(response.body)

          expect(result.dig("data", "rawTimeRows")).to eq([])
        end
      end
    end
  end

  describe "#enrich_raw_time_row" do
    subject(:make_request) { get :enrich_raw_time_row, params: request_params }
    let(:request_params) { { id: event_group.id, data: { raw_time_row: raw_time_row } } }
    let(:raw_time_row) { { raw_times: raw_time_attributes } }
    let(:raw_time_attributes) { { 0 => raw_time_attributes_1, 1 => raw_time_attributes_2 }.compact }
    let(:errors) { [] }

    let(:event_group) { event_groups(:hardrock_2016) }
    let(:event) { events(:hardrock_2016) }
    let(:effort_1) { efforts(:hardrock_2016_progress_sherman) }
    let(:effort_2) { efforts(:hardrock_2016_missing_telluride_out) }

    context "when a valid raw_time_row is submitted" do
      let(:raw_time_attributes_1) { { bib_number: effort_1.bib_number, entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: effort_1.bib_number, entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "adds split_time_exists and correctly interprets all attributes, returning no errors" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to eq([])

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["bibNumber"] }).to all eq(effort_1.bib_number.to_s)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Telluride Telluride])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([true, true])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end

    context "when the bib number includes leading zeros" do
      let(:raw_time_attributes_1) { { bib_number: "00#{effort_1.bib_number}", entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: "00#{effort_1.bib_number}", entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "does not result in an error" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to eq([])
        end
      end
    end

    context "when only one raw_time is included" do
      let(:raw_time_attributes_1) { { bib_number: effort_1.bib_number, entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { nil }

      via_login_and_jwt do
        it "adds split_time_exists and data_status" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to eq([])

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(1)
          expect(raw_times.map { |rt| rt["bibNumber"] }).to eq([effort_1.bib_number.to_s])
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1])
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(["Telluride"])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(["In"])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([true])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true])
        end
      end
    end

    context "when only one existing time is present" do
      let(:raw_time_attributes_1) { { bib_number: effort_2.bib_number.to_s, entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: effort_2.bib_number.to_s, entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "correctly computes split_time_exists" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to eq([])

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["bibNumber"] }).to all eq(effort_2.bib_number.to_s)
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Telluride Telluride])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([true, false])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end

    context "when a an entered_time is invalid" do
      let(:raw_time_attributes_1) { { bib_number: effort_1.bib_number, entered_time: "11:22:99", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: effort_1.bib_number, entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "returns the raw_time without a military_time attribute" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to eq([])

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["bibNumber"] }).to all eq(effort_1.bib_number.to_s)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Telluride Telluride])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq([nil, "11:23:34"])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:99 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([true, true])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end

    context "when the bib number is not found" do
      let(:raw_time_attributes_1) { { bib_number: "999", entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: "999", entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "returns data without adding split_time_exists" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to include("missing effort")

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["bibNumber"] }).to eq(%w[999 999])
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Telluride Telluride])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end

    context "when the split name is not found" do
      let(:raw_time_attributes_1) { { bib_number: effort_1.bib_number, entered_time: "11:22:33", split_name: "Nonexistent", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: effort_1.bib_number, entered_time: "11:23:34", split_name: "Nonexistent", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "returns data without adding split_time_exists and adds a descriptive error" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to include("invalid split name")

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["bibNumber"] }).to all eq(effort_1.bib_number.to_s)
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Nonexistent Nonexistent])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end

    context "when the bib number contains an asterisk" do
      let(:raw_time_attributes_1) { { bib_number: "9*9", entered_time: "11:22:33", split_name: "Telluride", with_pacer: "true", sub_split_kind: "in" } }
      let(:raw_time_attributes_2) { { bib_number: "9*9", entered_time: "11:23:34", split_name: "Telluride", with_pacer: "true", sub_split_kind: "out", stopped_here: "true" } }

      via_login_and_jwt do
        it "returns data without adding split_time_exists" do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig("data", "rawTimeRow")

          expect(raw_time_row["errors"]).to include("missing effort")

          raw_times = raw_time_row["rawTimes"]
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt["lap"] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt["bibNumber"] }).to eq(%w[9*9 9*9])
          expect(raw_times.map { |rt| rt["splitName"] }).to eq(%w[Telluride Telluride])
          expect(raw_times.map { |rt| rt["subSplitKind"] }).to eq(%w[In Out])
          expect(raw_times.map { |rt| rt["militaryTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["enteredTime"] }).to eq(%w[11:22:33 11:23:34])
          expect(raw_times.map { |rt| rt["splitTimeExists"] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt["stoppedHere"] }).to eq([false, true])
          expect(raw_times.map { |rt| rt["withPacer"] }).to eq([true, true])
        end
      end
    end
  end

  describe "#submit_raw_time_rows" do
    subject(:make_request) { post :submit_raw_time_rows, params: request_params }
    let(:request_params) { { id: event_group.id, data: raw_time_data, force_submit: force_submit } }
    let(:raw_time_data) { [{ "raw_time_row" => { "raw_times" => [raw_time_attributes_1, raw_time_attributes_2] } }] }

    let(:event_group) { event_groups(:hardrock_2016) }
    let(:effort_1) { efforts(:hardrock_2016_progress_sherman) }
    let(:effort_2) { efforts(:hardrock_2016_missing_telluride_out) }

    let(:bib_number_1) { effort_1.bib_number.to_s }
    let(:bib_number_2) { effort_2.bib_number.to_s }

    context "when data is valid and force_submit is true" do
      let(:raw_time_attributes_1) { { bib_number: bib_number_1, entered_time: "14:00:00", split_name: "Telluride", sub_split_kind: "in", source: "Live Entry (1)" } }
      let(:raw_time_attributes_2) { { bib_number: bib_number_1, entered_time: "14:05:00", split_name: "Telluride", sub_split_kind: "out", source: "Live Entry (1)" } }
      let(:force_submit) { "true" }

      via_login_and_jwt do
        it "overwrites existing duplicate split_times, creates raw_times, and does not return raw_time_rows" do
          prior_raw_time_count = RawTime.count
          expect(effort_1.ordered_split_times.first(3).map(&:military_time)).to eq(%w[06:00:00 13:44:00 13:47:00])
          response = make_request
          expect(response.status).to eq(201)
          result = JSON.parse(response.body)
          expect(result.dig("data", "rawTimeRows")).to eq([])
          effort_1.reload
          expect(effort_1.ordered_split_times.first(3).map(&:military_time)).to eq(%w[06:00:00 14:00:00 14:05:00])
          expect(RawTime.count).to eq(prior_raw_time_count + 2)
        end
      end
    end

    context "when data is valid but duplicates exist and force_submit is false" do
      let(:raw_time_attributes_1) { { bib_number: bib_number_1, entered_time: "14:00:00", split_name: "Telluride", sub_split_kind: "in", source: "Live Entry (1)" } }
      let(:raw_time_attributes_2) { { bib_number: bib_number_1, entered_time: "14:05:00", split_name: "Telluride", sub_split_kind: "out", source: "Live Entry (1)" } }
      let(:force_submit) { false }
      let(:expected) do
        [{ "rawTimes" =>
             [{ "id" => nil,
                "splitName" => "Telluride",
                "bibNumber" => bib_number_1,
                "absoluteTime" => nil,
                "enteredTime" => "14:00:00",
                "enteredLap" => nil,
                "withPacer" => false,
                "stoppedHere" => false,
                "source" => "Live Entry (1)",
                "remarks" => nil,
                "dataStatus" => "good",
                "lap" => 1,
                "splitTimeExists" => true,
                "militaryTime" => "14:00:00",
                "subSplitKind" => "In" },
              { "id" => nil,
                "splitName" => "Telluride",
                "bibNumber" => bib_number_1,
                "absoluteTime" => nil,
                "enteredTime" => "14:05:00",
                "enteredLap" => nil,
                "withPacer" => false,
                "stoppedHere" => false,
                "source" => "Live Entry (1)",
                "remarks" => nil,
                "dataStatus" => "good",
                "lap" => 1,
                "splitTimeExists" => true,
                "militaryTime" => "14:05:00",
                "subSplitKind" => "Out" }],
           "errors" => ["bad or duplicate time"] }]
      end

      via_login_and_jwt do
        it "does not overwrite existing duplicate split_times, does not create raw_times, and returns raw_time_rows" do
          prior_raw_time_count = RawTime.count
          expect(effort_1.ordered_split_times.first(3).map(&:military_time)).to eq(%w[06:00:00 13:44:00 13:47:00])
          response = make_request
          result = JSON.parse(response.body)
          expect(result.dig("data", "rawTimeRows")).to eq(expected)
          effort_1.reload
          expect(effort_1.ordered_split_times.first(3).map(&:military_time)).to eq(%w[06:00:00 13:44:00 13:47:00])
          expect(RawTime.count).to eq(prior_raw_time_count + 0)
        end
      end
    end

    context "when the bib number does not belong at the split" do
      let(:raw_time_attributes_1) { { bib_number: bib_number_1, entered_time: "09:00:00", split_name: "Aid 2", sub_split_kind: "in", source: "Live Entry (1)" } }
      let(:raw_time_attributes_2) { { bib_number: bib_number_1, entered_time: "09:05:00", split_name: "Aid 2", sub_split_kind: "out", source: "Live Entry (1)" } }
      let(:force_submit) { true }

      via_login_and_jwt do
        it "does not create raw_times or split_times" do
          expect { make_request }.to change { RawTime.count }.by(0).and change { SplitTime.count }.by(0)
        end

        it "returns raw_time_rows with descriptive errors" do
          response = make_request
          result = JSON.parse(response.body)
          expect(result.dig("data", "rawTimeRows").first["rawTimes"].size).to eq(2)
          expect(result.dig("data", "rawTimeRows").first["errors"]).to include("invalid split name")
        end
      end
    end

    context "when the bib number is invalid" do
      let(:raw_time_attributes_1) { { bib_number: "999", entered_time: "09:00:00", split_name: "Aid 2", sub_split_kind: "in", source: "Live Entry (1)" } }
      let(:raw_time_attributes_2) { { bib_number: "999", entered_time: "09:05:00", split_name: "Aid 2", sub_split_kind: "out", source: "Live Entry (1)" } }
      let(:force_submit) { true }

      via_login_and_jwt do
        it "does not create raw_times or split_times" do
          expect { make_request }.to change { RawTime.count }.by(0).and change { SplitTime.count }.by(0)
        end

        it "does not create raw_times or split_times and returns raw_time_rows with a descriptive error" do
          response = make_request
          result = JSON.parse(response.body)
          expect(result.dig("data", "rawTimeRows").first["rawTimes"].size).to eq(2)
          expect(result.dig("data", "rawTimeRows").first["errors"]).to include("missing effort")
        end
      end
    end

    context "when the split_name is invalid" do
      let(:raw_time_attributes_1) { { bib_number: bib_number_1, entered_time: "09:00:00", split_name: "Nonexistent", sub_split_kind: "in", source: "Live Entry (1)" } }
      let(:raw_time_attributes_2) { { bib_number: bib_number_1, entered_time: "09:05:00", split_name: "Nonexistent", sub_split_kind: "out", source: "Live Entry (1)" } }
      let(:force_submit) { true }

      via_login_and_jwt do
        it "does not create raw_times or split_times" do
          expect { make_request }.to change { RawTime.count }.by(0).and change { SplitTime.count }.by(0)
        end

        it "returns raw_time_rows with a descriptive error" do
          response = make_request
          result = JSON.parse(response.body)
          expect(result.dig("data", "rawTimeRows").first["rawTimes"].size).to eq(2)
          expect(result.dig("data", "rawTimeRows").first["errors"]).to include("invalid split name")
        end
      end
    end
  end

  describe "#not_expected" do
    subject(:make_request) { get :not_expected, params: request_params }
    let(:event_group) { event_groups(:sum) }
    let(:request_params) { { id: event_group.id, split_name: split_name } }

    context "when the split_name is valid" do
      let(:split_name) { "Molas Pass (Aid1)" }

      via_login_and_jwt do
        it "responds with an array of bib numbers that are not expected at the split" do
          response = make_request
          expect(response).to be_successful

          result = JSON.parse(response.body)
          expect(result.dig("data", "bib_numbers")).to match_array([101, 105, 109, 111, 114, 134, 140, 222, 333, 444, 777, 999])
        end
      end
    end

    context "when the split_name is the start" do
      let(:split_name) { "Start" }

      via_login_and_jwt do
        it "responds with an array of all started bib numbers" do
          response = make_request
          expect(response).to be_successful

          result = JSON.parse(response.body)
          expect(result.dig("data", "bib_numbers")).to match_array([101, 105, 109, 111, 114, 132, 134, 140, 222, 333, 444, 777, 999])
        end
      end
    end

    context "when the split_name is not valid" do
      let(:split_name) { "Non-existent" }

      via_login_and_jwt do
        it "responds with an error" do
          response = make_request
          expect(response).not_to be_successful

          result = JSON.parse(response.body)
          expect(result["errors"].first["detail"]["messages"]).to include(/non-existent is invalid/)
        end
      end
    end
  end
end
