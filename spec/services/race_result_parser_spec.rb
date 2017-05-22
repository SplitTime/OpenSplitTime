require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe RaceResultParser do
  let(:event) { create(:event) }
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
     'data' => {'#1_50k' => [['8', '1', '8', 'Chris Vargo', 'M', '35', '0:37:40.16', '0:55:44.38', '0:50:34.79', '0:58:55.84', '0:51:19.62', '0:16:33.35', '4:30:48.12', '4:30:48.12', '08:42'],
                             ['1', '2', '1', 'Joshua Arthur', 'M', '30', '0:43:03.86', '1:02:25.16', '0:50:47.26', '1:07:33.59', '0:50:36.63', '0:19:41.11', '4:54:07.59', '4:54:07.59', '09:28'],
                             ['5', '3', '5', 'Jason Schlarb', 'M', '39', '0:43:01.36', '1:02:07.50', '0:52:34.70', '1:08:27.81', '0:51:23.93', '0:18:01.15', '4:55:36.43', '4:55:36.43', '09:30'],
                             ['656', '28', '656', 'Taylor Nowlin', 'F', '26', '0:50:20.33', '1:14:15.40', '1:08:08.92', '1:18:06.69', '', '', '5:58:12.86', '5:58:12.86', '11:31'],
                             ['324', '31', '324', 'Justin Riederer', 'M', '26', '0:50:06.26', '1:15:46.73', '1:07:10.94', '1:22:20.34', '1:05:15.36', '0:20:29.76', '6:01:09.37', '6:01:09.37', '11:37'],
                             ['661', '*', '661', 'Casandra Perez', 'F', '31', '1:21:56.63', '2:38:01.85', '', '', '', '', '3:59:58.48', 'DNF', '*'],
                             ['633', '*', '633', 'Michele Hiner', 'F', '35', '', '', '', '', '', '', '', 'DNS', '*'],
                             ['630', '*', '630', 'Michael Hall', 'M', '37', '', '', '', '', '', '', '', 'DNS', '*']]}
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

  describe '#parse' do
    it 'interprets effort data and sends messages to a builder' do
      parser = RaceResultParser.new(event: event, json_response: json_response)
    end
  end
end
