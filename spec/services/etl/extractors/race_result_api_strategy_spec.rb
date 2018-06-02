RSpec.describe ETL::Extractors::RaceResultApiStrategy do
  subject { ETL::Extractors::RaceResultApiStrategy.new(raw_data, options) }
  let(:raw_data) { {'list' => {'last_change' => '2016-06-04 21:58:25',
                               'orders' => [],
                               'filters' => [],
                               'fields' => [
                                   {"expression" => "\"#\" & [BIB] & \". \" & ucase([FLNAME])"},
                                   {"expression" => "\"STATUS: \" & [STATUSTEXT]"},
                                   {"expression" => "\"START\""},
                                   {"expression" => "iif([TIMESET100];\"Time: \" & format(T100;\"Hh:mm:ss A\"))"},
                                   {"expression" => "\"AID 1\""},
                                   {"expression" => "iif([TIMESET151];\"Time: \" & format(T151;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET151];\"Split: \" & [Section1Split])"},
                                   {"expression" => "\"AID 2\""},
                                   {"expression" => "iif([TIMESET152];\"Time: \" & format(T152;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET152];\"Split: \" & [Section2Split])"},
                                   {"expression" => "\"AID 3\""},
                                   {"expression" => "iif([TIMESET153];\"Time: \" & format(T153;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET153];\"Split: \" & [Section3Split])"},
                                   {"expression" => "\"AID 4\""},
                                   {"expression" => "iif([TIMESET154];\"Time: \" & format(T154;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET154];\"Split: \" & [Section4Split])"},
                                   {"expression" => "\"AID 5\""},
                                   {"expression" => "iif([TIMESET155];\"Time: \" & format(T155;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET155];\"Split: \" & [Section5Split])"},
                                   {"expression" => "\"FINISH\""},
                                   {"expression" => "iif([TIMESET200];\"Time: \" & format(T200;\"Hh:mm:ss A\"))"},
                                   {"expression" => "iif([TIMESET200];\"Total Time: \" & [TIMETEXT])"}
                               ]},
                    'data' => {
                        '#1_50k' => [
                            ["194", "#194. MARK PERKINS", "STATUS: OK", "START", "Time: 7:05:05 AM", "AID 1", "Time: 8:05:19 AM", "Split: 1:00:14.64", "AID 2", "Time: 8:50:50 AM", "Split: 0:45:30.40", "AID 3", "Time: 9:37:57 AM", "Split: 0:47:06.79", "AID 4", "", "", "AID 5", "Time: 11:11:22 AM", "Split: ", "FINISH", "Time: 12:04:37 PM", "Total Time: 4:59:32.6"],
                            ["1065", "#1065. NOAH GLICK", "STATUS: OK", "START", "Time: 7:05:29 AM", "AID 1", "Time: 8:11:19 AM", "Split: 1:05:49.65", "AID 2", "Time: 8:58:41 AM", "Split: 0:47:22.83", "AID 3", "Time: 9:45:39 AM", "Split: 0:46:57.80", "AID 4", "Time: 10:30:59 AM", "Split: 0:45:19.88", "AID 5", "Time: 11:22:34 AM", "Split: 0:51:35.07", "FINISH", "Time: 12:18:13 PM", "Total Time: 5:12:44.0"],
                            ["167", "#167. SHAD MIKA", "STATUS: OK", "START", "Time: 7:05:42 AM", "AID 1", "Time: 8:22:41 AM", "Split: 1:16:58.85", "AID 2", "Time: 9:15:25 AM", "Split: 0:52:43.36", "AID 3", "Time: 10:07:56 AM", "Split: 0:52:30.96", "AID 4", "Time: 10:54:19 AM", "Split: 0:46:23.51", "AID 5", "", "", "FINISH", "", ""],
                            ["250", "#250. ALYSON WIEDENHEFT", "STATUS: DNS", "START", "", "AID 1", "", "", "AID 2", "", "", "AID 3", "", "", "AID 4", "", "", "AID 5", "", "", "FINISH", "", ""]
                        ]
                    }
  } }
  let(:options) { {} }

  describe '#extract' do
    it 'returns an array of attribute rows with effort data in OpenStruct format' do
      attribute_rows = subject.extract
      expect(attribute_rows.size).to eq(4)
      expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
      expect(attribute_rows.first[:name]).to eq('Mark Perkins')
      expect(attribute_rows.first[:bib]).to eq('194')
      expect(attribute_rows.first[:status]).to eq('OK')
      expect(attribute_rows.first[:time_0]).to eq('7:05:05 AM')
      expect(attribute_rows.last[:name]).to eq('Alyson Wiedenheft')
      expect(attribute_rows.last[:bib]).to eq('250')
      expect(attribute_rows.last[:status]).to eq('DNS')
      expect(attribute_rows.last[:time_0]).to eq('')
      pp attribute_rows.map(&:to_h)
    end
  end

  describe '#errors' do
    it 'exists if the provided hash does not include a ["list"] key' do
      test_data = raw_data
      test_data['list'] = nil
      subject.extract
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid fields/)
    end

    it 'exists if the provided hash does not include a ["list"]["fields"] key' do
      test_data = raw_data
      test_data['list']['fields'] = nil
      subject.extract
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid fields/)
    end

    it 'exists if the provided hash does not include a ["data"] key' do
      test_data = raw_data
      test_data['data'] = nil
      subject.extract
      expect(subject.errors).to be_present
      expect(subject.errors.first[:title]).to match(/Invalid data/)
    end
  end
end
