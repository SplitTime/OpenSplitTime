# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::RawTimes::SetAbsoluteTimeAndLap do
  subject { described_class.new(event_group, subject_raw_times) }
  let(:event_group) { event.event_group }
  let(:subject_raw_times) { [raw_time] }

  let!(:raw_time) do
    create(:raw_time,
           event_group: event_group,
           entered_lap: entered_lap,
           entered_time: entered_time,
           absolute_time: absolute_time,
           bib_number: bib_number,
           split_name: split_name,
           bitkey: 1,
           stopped_here: false)
  end

  let(:entered_lap) { nil }
  let(:entered_time) { nil }
  let(:absolute_time) { nil }
  let(:effort) { event.efforts.order(:bib_number).first }
  let(:bib_number) { effort.bib_number.to_s }
  let(:split_name) { event.ordered_splits.second.base_name }

  before do
    allow(::FindExpectedLap).to receive(:perform)
    allow(::IntendedTimeCalculator).to receive(:absolute_time_local)
  end

  describe '#perform' do
    let(:resulting_raw_times) { subject.perform }
    let(:resulting_raw_time) { resulting_raw_times.first }
    context 'for a single-lap event group' do
      let(:event) { events(:sum_100k) }

      shared_examples 'sets lap and time for a single-lap event' do
        context 'when absolute time is present' do
          let(:absolute_time) { '2020-04-04 07:30:00-0600' }
          it 'sets entered time and lap' do
            expect(resulting_raw_time.entered_time.to_datetime).to eq(absolute_time.to_datetime)
            expect(resulting_raw_time.lap).to eq(1)
          end
        end

        context 'when entered time is a datetime with time zone' do
          let(:entered_time) { '2020-04-04 07:30:00-0600' }
          it 'sets absolute time and lap' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.to_datetime)
            expect(resulting_raw_time.lap).to eq(1)
          end
        end

        context 'when entered time is a datetime without a time zone' do
          let(:entered_time) { '2020-04-04 07:30:00' }
          it 'sets absolute time and lap using the event group home time zone' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.in_time_zone(event_group.home_time_zone))
            expect(resulting_raw_time.lap).to eq(1)
          end
        end

        context 'when entered time is a military time' do
          let(:entered_time) { '07:30:00' }
          it 'sets lap' do
            expect(resulting_raw_time.lap).to eq(1)
          end

          it 'calls IntendedTimeCalculator to determine absolute time' do
            expect(::IntendedTimeCalculator).to receive(:absolute_time_local)
            resulting_raw_time
          end
        end
      end

      context 'when entered lap is nil' do
        include_examples 'sets lap and time for a single-lap event'
      end

      context 'when entered lap is provided' do
        let(:entered_lap) { 1 }

        include_examples 'sets lap and time for a single-lap event'
      end
    end

    context 'for a multi-lap event group' do
      let(:event) { events(:rufa_2017_24h) }
      let(:effort) { efforts(:rufa_2017_24h_progress_lap1) }
      context 'when entered lap is nil' do

        shared_examples 'uses FindExpectedLap to set the lap' do
          it 'calls FindExpectedLap to set the lap' do
            expect(::FindExpectedLap).to receive(:perform)
            resulting_raw_time
          end
        end

        context 'when absolute time is present' do
          let(:absolute_time) { '2017-02-11 11:55:00-0600' }
          it 'sets entered time' do
            expect(resulting_raw_time.entered_time.to_datetime).to eq(absolute_time.to_datetime)
          end

          include_examples 'uses FindExpectedLap to set the lap'
        end

        context 'when entered time is a datetime with time zone' do
          let(:entered_time) { '2017-02-11 11:55:00-0600' }
          it 'sets absolute time' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.to_datetime)
          end

          include_examples 'uses FindExpectedLap to set the lap'
        end

        context 'when entered time is a datetime without a time zone' do
          let(:entered_time) { '2017-02-11 11:55:00' }
          it 'sets absolute time using the event group home time zone' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.in_time_zone(event_group.home_time_zone))
          end

          include_examples 'uses FindExpectedLap to set the lap'
        end

        context 'when entered time is a military time' do
          let(:entered_time) { '07:30:00' }
          it 'calls IntendedTimeCalculator to determine absolute time' do
            expect(::IntendedTimeCalculator).to receive(:absolute_time_local)
            resulting_raw_time
          end

          include_examples 'uses FindExpectedLap to set the lap'
        end
      end

      context 'when entered lap is provided' do
        let(:entered_lap) { 2 }

        shared_examples 'uses entered lap to set the lap' do
          it 'sets lap to the entered lap' do
            expect(resulting_raw_time.lap).to eq(entered_lap)
          end
        end

        context 'when absolute time is present' do
          let(:absolute_time) { '2017-02-11 11:55:00-0600' }
          it 'sets entered time' do
            expect(resulting_raw_time.entered_time.to_datetime).to eq(absolute_time.to_datetime)
          end

          include_examples 'uses entered lap to set the lap'
        end

        context 'when entered time is a datetime with time zone' do
          let(:entered_time) { '2017-02-11 11:55:00-0600' }
          it 'sets absolute time' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.to_datetime)
          end

          include_examples 'uses entered lap to set the lap'
        end

        context 'when entered time is a datetime without a time zone' do
          let(:entered_time) { '2017-02-11 11:55:00' }
          it 'sets absolute time using the event group home time zone' do
            expect(resulting_raw_time.absolute_time.to_datetime).to eq(entered_time.in_time_zone(event_group.home_time_zone))
          end

          include_examples 'uses entered lap to set the lap'
        end

        context 'when entered time is a military time' do
          let(:entered_time) { '07:30:00' }
          it 'calls IntendedTimeCalculator to determine absolute time' do
            expect(::IntendedTimeCalculator).to receive(:absolute_time_local)
            resulting_raw_time
          end

          include_examples 'uses entered lap to set the lap'
        end
      end
    end
  end
end
