require 'rails_helper'

RSpec.describe DataImport::RaceResult::ParseStrategy do
  let(:raw_data) { {'list' => {'LastChange' => '2016-06-04 21:58:25',
                               'Orders' => [],
                               'Filters' => [],
                               'Fields' => [
                                   {'Expression' => "iif([RANK1]>0;[RANK1];\"*\")", 'Label' => 'Place'},
                                   {'Expression' => 'BIB', 'Label' => 'Bib'},
                                   {'Expression' => 'CorrectSpelling([DisplayName])', 'Label' => 'Name'},
                                   {'Expression' => 'SexMF', 'Label' => 'Sex'},
                                   {'Expression' => "iif([AGE]>0;[AGE];\"n/a\")", 'Label' => 'Age'},
                                   {'Expression' => 'Section1Split', 'Label' => 'Aid1'},
                                   {'Expression' => 'Section2Split', 'Label' => 'Aid2'},
                                   {'Expression' => 'Section3Split', 'Label' => 'Aid3'},
                                   {'Expression' => 'Section4Split', 'Label' => 'Aid4'},
                                   {'Expression' => 'Section5Split', 'Label' => 'Aid5'},
                                   {'Expression' => 'Section6Split', 'Label' => 'ToFinish'},
                                   {'Expression' => 'ElapsedTime', 'Label' => 'Elapsed'},
                                   {'Expression' => 'TimeOrStatus([ChipTime])', 'Label' => 'Time'},
                                   {'Expression' => "iif([TIMETEXT30]<>\"\" AND [STATUS]=0;[TIMETEXT30];\"*\")", 'Label' => 'Pace'}
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
      expect(attribute_rows.first[:aid1]).to eq('0:43:01.36')
      expect(attribute_rows.last[:aid1]).to eq('')
    end
  end
end
