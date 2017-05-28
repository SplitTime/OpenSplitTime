require 'rails_helper'

RSpec.describe DataImport::RaceResult::TransformStrategy do
  let(:parsed_data) { [
      OpenStruct.new({rr_id: '5', place: '3', bib: '5', name: 'Jatest Schtest', sex: 'M', age: '39',
                      section1_split: '0:43:01.36', section4_split: '1:08:27.81', section5_split: '0:51:23.93',
                      section2_split: '1:02:07.50', section3_split: '0:52:34.70', section6_split: '0:18:01.15',
                      elapsed: '4:55:36.43', time: '4:55:36.43', pace: '09:30'}),
      OpenStruct.new({rr_id: '656', place: '28', bib: '656', name: 'Tatest Notest', sex: 'F', age: '26',
                      section1_split: '0:50:20.33', section2_split: '1:14:15.40', section3_split: '1:08:08.92',
                      section4_split: '1:18:06.69', section5_split: '', section6_split: '',
                      elapsed: '5:58:12.86', time: '5:58:12.86', pace: '11:31'}),
      OpenStruct.new({rr_id: '324', place: '31', bib: '324', name: 'Justest Rietest', sex: 'M', age: '26',
                      section1_split: '0:50:06.26', section2_split: '1:15:46.73', section3_split: '1:07:10.94',
                      section4_split: '1:22:20.34', section5_split: '1:05:15.36', section6_split: '0:20:29.76',
                      elapsed: '6:01:09.37', time: '6:01:09.37', pace: '11:37'}),
      OpenStruct.new({rr_id: '661', place: '*', bib: '661', name: 'Castest Pertest', sex: 'F', age: '31',
                      section1_split: '1:21:56.63', section2_split: '2:38:01.85', section3_split: '',
                      section4_split: '', section5_split: '', section6_split: '',
                      elapsed: '3:59:58.48', time: 'DNF', pace: '*'}),
      OpenStruct.new({rr_id: '633', place: '*', bib: '633', name: 'Mictest Hintest', sex: 'F', age: '35',
                      section1_split: '', section2_split: '', section3_split: '',
                      section4_split: '', section5_split: '', section6_split: '',
                      elapsed: '', time: 'DNS', pace: '*'})
  ] }
  let(:options) { {event: event} }
  let(:event) { build_stubbed(:event_with_standard_splits, id: 1, concealed: true, in_sub_splits_only: true, splits_count: 7) }
  subject { DataImport::RaceResult::TransformStrategy.new(parsed_data, options) }

  describe '#transform' do
    before do
      _, time_points = lap_splits_and_time_points(event)
      allow(event).to receive(:required_time_points).and_return(time_points)
    end

    let(:first_row) { transformed_rows.first }
    let(:fourth_row) { transformed_rows.fourth }
    let(:last_row) { transformed_rows.last }
    let(:transformed_rows) { subject.transform }

    it 'returns the same number of OpenStructs as it is given' do
      expect(transformed_rows.count).to eq(5)
      expect(transformed_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
    end

    it 'returns rows with effort headers transformed to match the database' do
      expect(first_row.to_h.keys.sort)
          .to eq(%i(age bib_number child_records concealed event_id first_name gender last_name record_type))
    end

    it 'returns genders transformed to "male" or "female"' do
      expect(transformed_rows.map(&:gender)).to eq(%w(male female male female female))
    end

    it 'splits full names into first names and last names' do
      expect(transformed_rows.map(&:first_name)).to eq(%w(Jatest Tatest Justest Castest Mictest))
      expect(transformed_rows.map(&:last_name)).to eq(%w(Schtest Notest Rietest Pertest Hintest))
    end

    it 'assigns event.id and event.concealed to :event_id and :concealed keys' do
      expect(transformed_rows.map(&:event_id)).to eq([event.id] * parsed_data.size)
      expect(transformed_rows.map(&:concealed)).to eq([event.concealed] * parsed_data.size)
    end

    context 'when an event is not provided' do
      let(:options) { {} }

      it 'returns nil and adds an error' do
        expect(transformed_rows).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Event is missing/)
      end
    end

    context 'when event time_points do not match the provided segment times' do
      let(:event) { build_stubbed(:event_with_standard_splits, id: 1, concealed: true, in_sub_splits_only: true, splits_count: 6) }

      it 'returns nil and adds an error' do
        expect(transformed_rows).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Split mismatch error/)
      end
    end

    context 'for the child_records attribute' do
      it 'sorts split headers and returns an array of child_records' do
        records = first_row.child_records
        time_points = event.required_time_points
        expect(records.size).to eq(7)
        expect(records.map(&:record_type)).to eq([:split_time] * records.size)
        expect(records.map(&:lap)).to eq(time_points.map(&:lap))
        expect(records.map(&:split_id)).to eq(time_points.map(&:split_id))
        expect(records.map(&:bitkey)).to eq(time_points.map(&:bitkey))
        expect(records.map(&:time_from_start)).to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45])
      end

      it 'returns expected times_from_start array when some times are not present' do
        records = fourth_row.child_records
        expect(records.map(&:time_from_start)).to eq([0.0, 4916.63, 14398.48, nil, nil, nil, nil])
      end

      it 'returns expected times_from_start array when no times are present' do
        records = last_row.child_records
        expect(records.map(&:time_from_start)).to eq([nil] * records.size)
      end

      it 'returns expected split_id array when no times are present' do
        records = last_row.child_records
        time_points = event.required_time_points
        expect(records.map(&:split_id)).to eq(time_points.map(&:split_id))
      end
    end
  end
end
