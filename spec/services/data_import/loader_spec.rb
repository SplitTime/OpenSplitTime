require 'rails_helper'

RSpec.describe DataImport::Loader do
  let(:event) { create(:event_with_standard_splits, in_sub_splits_only: true, splits_count: 7) }
  let(:splits) { event.ordered_splits }
  let(:split_ids) { splits.ids }

  let(:transformed_data) { [
      ProtoRecord.new(record_type: :effort, age: '39', gender: 'male', bib_number: '5',
                      first_name: 'Jatest', last_name: 'Schtest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], bitkey: 1, time_from_start: 2581.36),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], bitkey: 1, time_from_start: 6308.86),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], bitkey: 1, time_from_start: 9463.56),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], bitkey: 1, time_from_start: 13571.37),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], bitkey: 1, time_from_start: 16655.3),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], bitkey: 1, time_from_start: 17736.45)]),
      ProtoRecord.new(record_type: :effort, age: '31', gender: 'female', bib_number: '661',
                      first_name: 'Castest', last_name: 'Pertest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], bitkey: 1, time_from_start: 4916.63),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], bitkey: 1, time_from_start: 14398.48),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], bitkey: 1, time_from_start: nil)]),
      ProtoRecord.new(record_type: :effort, age: '35', gender: 'female', bib_number: '633',
                      first_name: 'Mictest', last_name: 'Hintest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], bitkey: 1, time_from_start: nil)]),
      ProtoRecord.new(record_type: :effort, age: '0', gender: '', bib_number: '62',
                      first_name: 'N.n.', last_name: '62', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], bitkey: 1, time_from_start: nil)])
  ]}
  let(:options) { {event: event} }
  subject { DataImport::Loader.new(transformed_data, options) }

  describe '#load_records' do
    it 'creates new records of the parent class and accurately saves attributes' do
      efforts = Effort.all
      expect(efforts.size).to eq(0)
      subject.load_records
      expect(efforts.size).to eq(3)
      expect(efforts.map(&:first_name)).to eq(%w(Jatest Castest Mictest))
      expect(efforts.map(&:bib_number)).to eq([5, 661, 633])
      expect(efforts.map(&:gender)).to eq(%w(male female female))
      expect(efforts.map(&:event_id)).to eq([event.id] * efforts.size)
    end

    it 'accurately saves new child records and accurately saves attributes' do
      split_times = SplitTime.all
      expect(split_times.size).to eq(0)
      subject.load_records
      expect(split_times.size).to eq(10)
      expect(split_times.map(&:split_id)).to eq(split_ids.cycle.first(split_times.size))
      expect(split_times.map(&:time_from_start)).to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45, 0.0, 4916.63, 14398.48])
      expect(split_times.map(&:effort_id)).to eq([Effort.first.id] * 7 + [Effort.second.id] * 3)
    end
  end
end
