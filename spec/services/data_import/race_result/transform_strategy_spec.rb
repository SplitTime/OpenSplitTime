require 'rails_helper'

RSpec.describe DataImport::RaceResult::TransformStrategy do
  let(:parsed_data) { [
      OpenStruct.new({rr_id: "5", place: "3", bib: "5", name: "Jatest Schtest", sex: "M", age: "39", aid1: "0:43:01.36", aid2: "1:02:07.50", aid3: "0:52:34.70", aid4: "1:08:27.81", aid5: "0:51:23.93", tofinish: "0:18:01.15", elapsed: "4:55:36.43", time: "4:55:36.43", pace: "09:30"}),
      OpenStruct.new({rr_id: "656", place: "28", bib: "656", name: "Tatest Notest", sex: "F", age: "26", aid1: "0:50:20.33", aid2: "1:14:15.40", aid3: "1:08:08.92", aid4: "1:18:06.69", aid5: "", tofinish: "", elapsed: "5:58:12.86", time: "5:58:12.86", pace: "11:31"}),
      OpenStruct.new({rr_id: "324", place: "31", bib: "324", name: "Justest Rietest", sex: "M", age: "26", aid1: "0:50:06.26", aid2: "1:15:46.73", aid3: "1:07:10.94", aid4: "1:22:20.34", aid5: "1:05:15.36", tofinish: "0:20:29.76", elapsed: "6:01:09.37", time: "6:01:09.37", pace: "11:37"}),
      OpenStruct.new({rr_id: "661", place: "*", bib: "661", name: "Castest Pertest", sex: "F", age: "31", aid1: "1:21:56.63", aid2: "2:38:01.85", aid3: "", aid4: "", aid5: "", tofinish: "", elapsed: "3:59:58.48", time: "DNF", pace: "*"}),
      OpenStruct.new({rr_id: "633", place: "*", bib: "633", name: "Mictest Hintest", sex: "F", age: "35", aid1: "", aid2: "", aid3: "", aid4: "", aid5: "", tofinish: "", elapsed: "", time: "DNS", pace: "*"})
  ] }
  let(:options) { {} }
  subject { DataImport::RaceResult::TransformStrategy.new(parsed_data, options) }

  describe '#transform' do
    let(:transformed_rows) { subject.transform }

    it 'returns the same number of OpenStructs as it is given' do
      expect(transformed_rows.count).to eq(5)
      expect(transformed_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
    end

    it 'returns rows with effort headers transformed to match the database' do
      subject_row = transformed_rows.first
      expect(subject_row).to be_nil
      expect(subject_row.to_h.keys.sort).to eq([:age, :aid1, :aid2, :aid3, :aid4, :aid5, :bib_number, :elapsed,
                                                :first_name, :gender, :last_name, :pace, :place, :rr_id, :time, :tofinish])
    end

    it 'returns genders transformed to "male" or "female"' do
      expect(transformed_rows.map(&:gender)).to eq(%w(male female male female female))
    end

    it 'splits full names into first names and last names' do
      expect(transformed_rows.map(&:first_name)).to eq(%w(Jatest Tatest Justest Castest Mictest))
      expect(transformed_rows.map(&:last_name)).to eq(%w(Schtest Notest Rietest Pertest Hintest))
    end
  end
end
