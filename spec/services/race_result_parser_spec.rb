require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe RaceResultParser do
  let(:event) { build_stubbed(:event_with_standard_splits, splits_count: 7, in_sub_splits_only: true) }
  let(:json_response) {
    {'list' => {'LastChange' => '2016-06-04 21:58:25',
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

  describe '#initialize' do
    it 'initializes when given an event and a json_response' do
      expect { RaceResultParser.new(event: event, json_response: json_response) }
          .not_to raise_error
    end

    it 'raises an error when not given an event' do
      expect { RaceResultParser.new(event: nil, json_response: json_response) }
          .to raise_error(/must include event/)
    end

    it 'raises an error when not given a race_result_event_id' do
      expect { RaceResultParser.new(event: event, json_response: nil) }
          .to raise_error(/must include json_response/)
    end
  end

  describe '#errors' do
    it 'exists if the event splits do not match the json_response splits' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      time_points.delete_at(2) # Remove a time_point to cause a mismatch
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      parser = RaceResultParser.new(event: test_event, json_response: json_response)
      expect(parser.errors).to be_one
      expect(parser.errors.first[:title]).to eq('Split mismatch error')
    end

    it 'is empty if the event splits match the json_response splits' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      parser = RaceResultParser.new(event: test_event, json_response: json_response)
      expect(parser.errors).to be_empty
    end

    it 'exists if the json_response contains no ["list"] key' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      json_response['list'] = nil
      parser = RaceResultParser.new(event: test_event, json_response: json_response)
      expect(parser.errors).to be_one
      expect(parser.errors.first[:title]).to eq('Malformed response error')
    end

    it 'exists if the json_response contains no ["list"]["Fields]" key' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      json_response['list']['Fields'] = nil
      parser = RaceResultParser.new(event: test_event, json_response: json_response)
      expect(parser.errors).to be_one
      expect(parser.errors.first[:title]).to eq('Malformed response error')
    end

    it 'exists if the json_response contains no ["data"] key' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      json_response['data'] = nil
      parser = RaceResultParser.new(event: test_event, json_response: json_response)
      expect(parser.errors).to be_one
      expect(parser.errors.first[:title]).to eq('Malformed response error')
    end
  end

  describe '#parsed_effort_data' do
    let(:parser) { RaceResultParser.new(event: event, json_response: json_response) }

    it 'returns response data in the form of an array of structs with elapsed_time_data' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      expect(parser.parsed_effort_data.size).to eq(5)
      expect(parser.parsed_effort_data.first.elapsed_time_data.keys).to eq(time_points)
      expect(parser.parsed_effort_data.first.elapsed_time_data.values)
          .to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45])
    end

    it 'includes full_name, age, bib_number, and gender' do
      test_event = event
      _, time_points = lap_splits_and_time_points(test_event)
      allow(test_event).to receive(:required_time_points).and_return(time_points)
      expect(parser.parsed_effort_data.map(&:bib_number)).to eq(%w(5 656 324 661 633))
      expect(parser.parsed_effort_data.map(&:full_name))
          .to eq(['Jatest Schtest', 'Tatest Notest', 'Justest Rietest', 'Castest Pertest', 'Mictest Hintest'])
      expect(parser.parsed_effort_data.map(&:gender)).to eq(%w(M F M F F))
      expect(parser.parsed_effort_data.map(&:age)).to eq(%w(39 26 26 31 35))
    end
  end
end
