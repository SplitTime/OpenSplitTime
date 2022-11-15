# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::Loaders::AsyncInsertStrategy do
  subject { described_class.new(proto_records, options) }
  let(:event) { events(:ggd30_50k) }
  let(:start_time) { event.scheduled_start_time }
  let(:subject_splits) { event.ordered_splits }
  let(:split_ids) { subject_splits.map(&:id) }

  let(:valid_proto_records) do
    [
      ProtoRecord.new(
        record_type: :effort, age: "39", gender: "male", bib_number: "5",
        first_name: "Jatest", last_name: "Schtest", event_id: event.id,
        children: [
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 2581),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 6308),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: start_time + 9463),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: start_time + 13_571),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: start_time + 16_655),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: start_time + 17_736)
        ]
      ),
      ProtoRecord.new(
        record_type: :effort, age: "31", gender: "female", bib_number: "661",
        first_name: "Castest", last_name: "Pertest", event_id: event.id,
        children: [
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 4916),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 14_398)
        ]
      ),
      ProtoRecord.new(
        record_type: :effort, age: "35", gender: "female", bib_number: "633",
        first_name: "Mictest", last_name: "Hintest", event_id: event.id,
        children: []
      )
    ]
  end

  let(:invalid_proto_record) do
    [
      ProtoRecord.new(
        record_type: :effort, age: "0", gender: "", bib_number: "62",
        first_name: "N.n.", last_name: "62", event_id: event.id,
        children: []
      )
    ]
  end

  let(:proto_with_invalid_child) do
    [
      ProtoRecord.new(
        record_type: :effort, age: "40", gender: "male", bib_number: "500",
        first_name: "Johtest", last_name: "Apptest", event_id: event.id,
        children: [
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 1000),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 2000),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: nil),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: start_time + 5000)
        ]
      )
    ]
  end

  let(:proto_with_military_times) do
    [
      ProtoRecord.new(
        record_type: :effort, age: "40", gender: "male", bib_number: "500",
        first_name: "Johtest", last_name: "Apptest", event_id: event.id,
        children: [
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, military_time: "06:00:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, military_time: "07:20:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, military_time: "08:40:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, military_time: "10:00:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, military_time: "11:20:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, military_time: "12:40:00"),
          ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, military_time: "14:00:00")
        ]
      )
    ]
  end

  let(:all_proto_records) { valid_proto_records + invalid_proto_record }
  let(:options) { { event: event, import_job: import_job, unique_key: unique_key } }
  let!(:import_job) { create(:import_job, parent_type: "Event", parent_id: event.id, format: :test_format) }
  let(:unique_key) { nil }

  describe "#load_records" do
    context "when all provided records are valid and none previously exists" do
      let(:proto_records) { valid_proto_records }

      it "assigns attributes and creates new records of the parent class" do
        expect { subject.load_records }.to change { Effort.count }.by(3)
        subject_efforts = Effort.last(3)

        expect(subject_efforts.map(&:first_name)).to match_array(%w[Jatest Castest Mictest])
        expect(subject_efforts.map(&:bib_number)).to match_array([5, 661, 633])
        expect(subject_efforts.map(&:gender)).to match_array(%w[male female female])
        expect(subject_efforts.map(&:event_id)).to all eq(event.id)
      end

      it "assigns attributes and saves new child records" do
        expect { subject.load_records }.to change { SplitTime.count }.by(10)
        subject_efforts = Effort.last(3)
        subject_split_times = SplitTime.last(10)

        expect(subject_split_times.map(&:split_id)).to match_array(split_ids.cycle.first(subject_split_times.size))
        expected_absolute_times = [0, 2581, 6308, 9463, 13_571, 16_655, 17_736, 0, 4916, 14_398].map { |e| start_time + e }
        expect(subject_split_times.map(&:absolute_time)).to match_array(expected_absolute_times)
        expect(subject_split_times.map(&:effort_id)).to match_array([subject_efforts.first.id] * 7 + [subject_efforts.second.id] * 3)
      end

      it "updates success count on the import job" do
        subject.load_records
        expect(import_job.succeeded_count).to eq(3)
        expect(import_job.failed_count).to eq(0)
        expect(import_job.ignored_count).to eq(0)
      end
    end

    context "when valid records have children with military_time attributes" do
      let(:proto_records) { proto_with_military_times }

      it "assigns attributes and creates new records of the parent class" do
        expect { subject.load_records }.to change { Effort.count }.by(1)
        effort = Effort.last

        expect(effort.first_name).to eq("Johtest")
        expect(effort.bib_number).to eq(500)
        expect(effort.gender).to eq("male")
        expect(effort.event_id).to eq(event.id)
      end

      it "assigns attributes and saves new child records" do
        expect { subject.load_records }.to change { SplitTime.count }.by(7)
        effort = Effort.last
        subject_split_times = SplitTime.last(7)

        expect(subject_split_times.map(&:split_id)).to match_array(split_ids.cycle.first(subject_split_times.size))
        expect(subject_split_times.map(&:time_from_start)).to match_array([0, 80.minutes, 160.minutes, 240.minutes, 320.minutes, 400.minutes, 480.minutes])
        expect(subject_split_times.map(&:effort_id)).to all eq(effort.id)
      end
    end

    context "when one or more records fails validation" do
      let(:proto_records) { valid_proto_records }
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }

      before do
        existing_effort = create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number])
        create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
               bitkey: first_child[:sub_split_bitkey], time_from_start: 0)
        create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
               bitkey: second_child[:sub_split_bitkey], time_from_start: 1000)
      end

      it "inserts only those records that do not fail validation" do
        expect { subject.load_records }.to change { Effort.count }.by(2).and change { SplitTime.count }.by(3)
      end

      it "sets success count and failure count on the import job" do
        subject.load_records
        expect(import_job.succeeded_count).to eq(2)
        expect(import_job.failed_count).to eq(1)
        expect(import_job.ignored_count).to eq(0)
      end

      it "returns a descriptive error message" do
        subject.load_records
        expect(subject.errors.first.dig(:detail, :messages).first).to match(/Bib number \d already exists/)
      end
    end

    context "when a unique key is provided" do
      let(:unique_key) { [:first_name, :last_name, :birthdate, :event_id] }
      let(:proto_records) { valid_proto_records }

      context "when no records match the unique key" do
        it "assigns attributes and creates new records" do
          expect { subject.load_records }.to change { Effort.count }.by(3)
          subject_efforts = Effort.last(3)

          expect(subject_efforts.map(&:first_name)).to match_array(%w[Jatest Castest Mictest])
          expect(subject_efforts.map(&:bib_number)).to match_array([5, 661, 633])
          expect(subject_efforts.map(&:gender)).to match_array(%w[male female female])
          expect(subject_efforts.map(&:event_id)).to all eq(event.id)
        end
      end

      context "when an existing record matches the unique key" do
        let!(:existing_effort) do
          create(:effort,
                 event: event,
                 first_name: valid_proto_records.first[:first_name],
                 last_name: valid_proto_records.first[:last_name],
                 birthdate: valid_proto_records.first[:birthdate])
        end

        it "creates new records only for non-matching protos" do
          expect { subject.load_records }.to change { Effort.count }.by(2)
          subject_efforts = Effort.last(2)

          expect(subject_efforts.map(&:first_name)).to match_array(%w[Castest Mictest])
          expect(subject_efforts.map(&:bib_number)).to match_array([661, 633])
          expect(subject_efforts.map(&:gender)).to match_array(%w[female female])
          expect(subject_efforts.map(&:event_id)).to all eq(event.id)
        end

        it "ignores the matching record" do
          expect(existing_effort).not_to receive(:update)
          expect(existing_effort).not_to receive(:save)
          subject.load_records

          expect(import_job.succeeded_count).to eq(2)
          expect(import_job.failed_count).to eq(0)
          expect(import_job.ignored_count).to eq(1)
        end
      end
    end

    context "when any provided record is invalid" do
      let(:proto_records) { all_proto_records }

      it "inserts only those records that are valid" do
        expect { subject.load_records }.to change { Effort.count }.by(3).and change { SplitTime.count }.by(10)
      end

      it "sets success count and failure count on the import job" do
        subject.load_records
        expect(import_job.succeeded_count).to eq(3)
        expect(import_job.failed_count).to eq(1)
        expect(import_job.ignored_count).to eq(0)
      end

      it "returns a descriptive error message" do
        subject.load_records
        expect(subject.errors.first.dig(:detail, :messages).first).to match(/Gender can't be blank/)
      end
    end

    context "when a parent record is valid but at least one child record is invalid" do
      let(:proto_records) { proto_with_invalid_child }

      it "rolls back the transaction" do
        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(0)
      end

      it "sets success count and failure count on the import job" do
        subject.load_records
        expect(import_job.succeeded_count).to eq(0)
        expect(import_job.failed_count).to eq(1)
        expect(import_job.ignored_count).to eq(0)
      end

      it "returns a descriptive error message" do
        subject.load_records
        expect(subject.errors.first.dig(:detail, :messages).first).to match(/Split times absolute time can't be blank/)
      end
    end
  end
end
