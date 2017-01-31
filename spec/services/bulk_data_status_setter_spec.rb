require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe BulkDataStatusSetter do
  describe '#initialize' do
    it 'initializes with an efforts array and a times_container in an args hash' do
      efforts = [FactoryGirl.build_stubbed(:effort)]
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      expect { BulkDataStatusSetter.new(efforts: efforts,
                                        times_container: times_container) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no efforts argument is given' do
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      expect { BulkDataStatusSetter.new(times_container: times_container) }
          .to raise_error(/must include efforts/)
    end

    it 'raises an ArgumentError if a param other than effort or times_container is given' do
      efforts = [FactoryGirl.build_stubbed(:effort)]
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      random_param = 123
      expect { BulkDataStatusSetter.new(efforts: efforts,
                                        times_container: times_container,
                                        random_param: random_param) }
          .to raise_error(/may not include random_param/)
    end
  end

  xdescribe '#set_data_status' do
    before do
      FactoryGirl.reload
    end

    let(:single_lap_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 1, efforts_count: 1) }
    let(:event_efforts) { single_lap_event.efforts }
    let(:event_split_times) { event_efforts.map(&:split_times).flatten }
    let(:ordered_split_times) { event_split_times.sort_by { |st| [st.lap, st.split.distance_from_start, st.sub_split_bitkey] } }

    it 'sends a correct message to EffortDataStatusSetter' do
      split_times = ordered_split_times
      effort = event_efforts.first
      efforts = [effort]
      lap_splits = lap_splits_and_time_points(single_lap_event).first
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      bulk_setter = BulkDataStatusSetter.new(efforts: efforts, times_container: times_container)
      allow(bulk_setter).to receive(:all_split_times).and_return(split_times)
      allow(bulk_setter).to receive(:lap_splits).and_return(lap_splits)
      allow(EffortDataStatusSetter).to receive(:new)
      bulk_setter.set_data_status
      expect(EffortDataStatusSetter).to have_received(:new).with({effort: effort,
                                                                  ordered_split_times: effort.split_times,
                                                                  lap_splits: lap_splits,
                                                                  times_container: times_container})
    end
  end
end