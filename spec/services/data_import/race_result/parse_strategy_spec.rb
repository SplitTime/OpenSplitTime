require 'rails_helper'

RSpec.describe DataImport::RaceResult::ParseStrategy do
  let(:raw_data) { {'list' => {'last_change' => '2016-06-04 21:58:25',
                               'orders' => [],
                               'filters' => [],
                               'fields' => [
                                   {'expression' => "iif([RANK1]>0;[RANK1];\"*\")", 'label' => 'Place'},
                                   {'expression' => 'BIB', 'label' => 'Bib'},
                                   {'expression' => 'CorrectSpelling([DisplayName])', 'label' => 'Name'},
                                   {'expression' => 'SexMF', 'label' => 'Sex'},
                                   {'expression' => "iif([AGE]>0;[AGE];\"n/a\")", 'label' => 'Age'},
                                   {'expression' => 'Section1Split', 'label' => 'Aid1'},
                                   {'expression' => 'Section2Split', 'label' => 'Aid2'},
                                   {'expression' => 'Section3Split', 'label' => 'Aid3'},
                                   {'expression' => 'Section4Split', 'label' => 'Aid4'},
                                   {'expression' => 'Section5Split', 'label' => 'Aid5'},
                                   {'expression' => 'Section6Split', 'label' => 'ToFinish'},
                                   {'expression' => 'ElapsedTime', 'label' => 'Elapsed'},
                                   {'expression' => 'TimeOrStatus([ChipTime])', 'label' => 'Time'},
                                   {'expression' => "iif([TIMETEXT30]<>\"\" AND [STATUS]=0;[TIMETEXT30];\"*\")", 'label' => 'Pace'}
                               ]},
                    'data' => {'#1_50k' => [['5', '3', '5', 'Jatest Schtest', 'M', '39', '0:43:01.36', '1:02:07.50', '0:52:34.70', '1:08:27.81', '0:51:23.93', '0:18:01.15', '4:55:36.43', '4:55:36.43', '09:30'],
                                            ['656', '28', '656', 'Tatest Notest', 'F', '26', '0:50:20.33', '1:14:15.40', '1:08:08.92', '1:18:06.69', '', '', '5:58:12.86', '5:58:12.86', '11:31'],
                                            ['324', '31', '324', 'Justest Rietest', 'M', '26', '0:50:06.26', '1:15:46.73', '1:07:10.94', '1:22:20.34', '1:05:15.36', '0:20:29.76', '6:01:09.37', '6:01:09.37', '11:37'],
                                            ['661', '*', '661', 'Castest Pertest', 'F', '31', '1:21:56.63', '2:38:01.85', '', '', '', '', '3:59:58.48', 'DNF', '*'],
                                            ['633', '*', '633', 'Mictest Hintest', 'F', '35', '', '', '', '', '', '', '', 'DNS', '*']]}
  } }
  let(:options) { {} }
  subject { DataImport::RaceResult::ParseStrategy.new(raw_data, options) }

  describe '#parse' do
    it 'returns an array of attribute rows with effort data in OpenStruct format' do
      attribute_rows = subject.parse
      expect(attribute_rows.size).to eq(5)
      expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
      expect(attribute_rows.first[:name]).to eq('Jatest Schtest')
      expect(attribute_rows.first[:section1_split]).to eq('0:43:01.36')
      expect(attribute_rows.last[:section1_split]).to eq('')
    end
  end

  describe '#errors' do
    it 'exists if the provided hash does not include a ["list"] key' do
      test_data = raw_data
      test_data['list'] = nil
      subject.parse
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid fields/)
    end

    it 'exists if the provided hash does not include a ["list"]["fields"] key' do
      test_data = raw_data
      test_data['list']['fields'] = nil
      subject.parse
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid fields/)
    end

    it 'exists if the provided hash does not include a ["data"] key' do
      test_data = raw_data
      test_data['data'] = nil
      subject.parse
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid data/)
    end
  end
end
