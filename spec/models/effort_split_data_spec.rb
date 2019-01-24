# frozen_string_literal: true

RSpec.describe EffortSplitData, type: :model do
  subject { EffortSplitData.new(absolute_times_local: absolute_times_local) }
  let(:other) { EffortSplitData.new(absolute_times_local: days_and_times_other) }

  describe '#<=>' do
    let(:effort_split_data_objects) { [subject, other] }

    context 'when the other object contains a later first absolute_time_local' do
      let(:absolute_times_local) { [DateTime.parse('2017-07-01 06:00:00'), DateTime.parse('2017-07-01 06:30:00')] }
      let(:days_and_times_other) { [DateTime.parse('2017-07-01 06:15:00'), DateTime.parse('2017-07-01 06:45:00')] }

      it 'sorts effort_split_data objects based on the first available time contained in absolute_times_local' do
        expect(effort_split_data_objects.sort).to eq([subject, other])
      end
    end

    context 'when the other object contains an earlier first absolute_time_local' do
      let(:absolute_times_local) { [DateTime.parse('2017-07-01 06:00:00'), DateTime.parse('2017-07-01 06:30:00')] }
      let(:days_and_times_other) { [DateTime.parse('2017-07-01 05:15:00'), DateTime.parse('2017-07-01 06:45:00')] }

      it 'sorts effort_split_data objects based on the first available time contained in absolute_times_local' do
        expect(effort_split_data_objects.sort).to eq([other, subject])
      end
    end

    context 'when the other object contains no first absolute_time_local but an earlier second absolute_time_local' do
      let(:absolute_times_local) { [DateTime.parse('2017-07-01 06:00:00'), DateTime.parse('2017-07-01 06:30:00')] }
      let(:days_and_times_other) { [nil, DateTime.parse('2017-07-01 05:45:00')] }

      it 'sorts effort_split_data objects based on the first available time contained in absolute_times_local' do
        expect(effort_split_data_objects.sort).to eq([other, subject])
      end
    end

    context 'when the other object contains no absolute_time_local' do
      let(:absolute_times_local) { [DateTime.parse('2017-07-01 06:00:00'), DateTime.parse('2017-07-01 06:30:00')] }
      let(:days_and_times_other) { [nil, nil] }

      it 'sorts substituting zero for the empty array' do
        expect(effort_split_data_objects.sort).to eq([other, subject])
      end
    end
  end
end
