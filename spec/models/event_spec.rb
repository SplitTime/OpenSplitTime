require 'rails_helper'

# t.integer  "course_id"
# t.integer  "organization_id"
# t.string   "name"
# t.datetime "start_time"

RSpec.describe Event, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe 'initialize' do
    let(:course) { Course.create!(name: 'Slo Mo 100 CCW') }
    let(:course2) { Course.create!(name: 'Slo Mo 100 CW') }

    it 'is valid when created with a course, a name, and a start time' do
      event = Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01 06:00:00', laps_required: 1)

      expect(Event.all.count).to eq(1)
      expect(event.course).to eq(course)
      expect(event.name).to eq('Slo Mo 100 2015')
      expect(event.start_time).to eq('2015-07-01 06:00:00'.in_time_zone)
      expect(event).to be_valid
    end

    it 'is invalid without a course' do
      event = Event.new(course: nil, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:course_id]).to include("can't be blank")
    end

    it 'is invalid without a name' do
      event = Event.new(course: course, name: nil, start_time: '2015-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a start date' do
      event = Event.new(course: course, name: 'Slo Mo 100 2015', start_time: nil, laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without a laps_required' do
      event = Event.new(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: nil)
      expect(event).not_to be_valid
      expect(event.errors[:laps_required]).to include("can't be blank")
    end

    it 'does not permit duplicate names' do
      Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: 1)
      event = Event.new(course: course2, name: 'Slo Mo 100 2015', start_time: '2016-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include('has already been taken')
    end
  end

  describe 'methods that produce lap_splits and time_points' do
    let(:event) { FactoryGirl.build_stubbed(:event, laps_required: 2) }
    let(:start_split) { FactoryGirl.build_stubbed(:start_split, id: 111) }
    let(:intermediate_split1) { FactoryGirl.build_stubbed(:split, id: 102) }
    let(:intermediate_split2) { FactoryGirl.build_stubbed(:split, id: 103) }
    let(:finish_split) { FactoryGirl.build_stubbed(:finish_split, id: 112) }
    let(:splits) { [start_split, intermediate_split1, intermediate_split2, finish_split] }

    describe '#required_lap_splits' do
      it 'returns an empty array when laps_required is zero' do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits).to eq([])
      end

      it 'returns an array whose size is equal to laps_required * number of splits' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
      end

      it 'returns an array of LapSplit objects ordered by lap, split distance, and bitkey' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
        expect(required_lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
        expect(required_lap_splits.map(&:split).map(&:id)).to eq([111, 102, 103, 112] * 2)
      end
    end


    describe '#required_time_points' do
      it 'returns an empty array when laps_required is zero' do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points).to eq([])
      end

      it 'returns an array whose size is equal to laps_required * number of sub_splits' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.size).to eq(12)
      end

      it 'returns an array of TimePoint objects ordered by lap, split distance, and bitkey' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
        expect(required_time_points.map(&:split_id)).to eq([111, 102, 102, 103, 103, 112] * 2)
        expect(required_time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
      end
    end
  end

  describe '#multiple_laps?' do
    it 'returns false if the event requires exactly one lap' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 1)
      expect(event.multiple_laps?).to be_falsey
    end

    it 'returns true if the event requires more than one lap' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 2)
      expect(event.multiple_laps?).to be_truthy
    end

    it 'returns true if the event requires zero (i.e. unlimited) laps' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 0)
      expect(event.multiple_laps?).to be_truthy
    end
  end

  describe '#maximum_laps' do
    it 'returns laps_required when laps_required is 1' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 1)
      expect(event.maximum_laps).to eq(1)
    end

    it 'returns laps_required when laps_required is greater than 1' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 3)
      expect(event.maximum_laps).to eq(3)
    end

    it 'returns nil when laps_required is 0' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 0)
      expect(event.maximum_laps).to eq(nil)
    end
  end

  describe '#pick_partner_with_banner' do
    context 'where multiple partners exist for both the subject event and another event' do
      let!(:event) { create(:event) }
      let!(:wrong_event) { create(:event) }
      let!(:related_partners_with_banners) { create_list(:partner_with_banner, 3, event: event) }
      let!(:related_partners_without_banners) { create_list(:partner, 3, event: event) }
      let!(:unrelated_partners_with_banners) { create_list(:partner_with_banner, 3, event: wrong_event) }
      let!(:unrelated_partners_without_banners) { create_list(:partner, 3, event: wrong_event) }

      it 'returns a random partner with a banner for the event' do
        partners = []
        100.times { partners << event.pick_partner_with_banner }
        expect(partners.map(&:event_id).uniq).to eq([event.id])
        expect(partners.map(&:banner_file_name)).to all ( be_present )
      end
    end

    context 'where multiple partners with banners for the event exist and one is weighted more heavily' do
      # Four partners with weight: 1 and one partner with weight: 10 means the weighted partner should receive,
      # on average, about 71% of hits.
      let!(:event) { create(:event) }
      let!(:weighted_partner) { create(:partner_with_banner, event: event, weight: 10) }
      let!(:unweighted_partners) { create_list(:partner_with_banner, 4, event: event) }

      it 'returns a random partner giving weight to the weighted partner' do
        partners = []
        100.times { partners << event.pick_partner_with_banner }
        partners_count = partners.count_by(&:id)
        expect(partners_count[weighted_partner.id]).to be > (50)
        unweighted_partners.each do |unweighted_partner|
          expect(partners_count[unweighted_partner.id]).to be_between(1, 20).inclusive
        end
      end
    end

    context 'where no partners with banners for the event exist' do
      let!(:event) { create(:event) }

      it 'returns nil' do
        create(:partner, event: event) # Without a banner
        expect(event.pick_partner_with_banner).to be_nil
      end
    end
  end

  describe '#live_entry_attributes' do
    let(:event) { build_stubbed(:event_with_standard_splits) }
    let(:splits) { event.splits.sort_by(&:distance_from_start) }

    it 'returns an array of information for building live entry screens' do
      allow(event).to receive(:ordered_splits).and_return(splits)
      split = splits.second
      expected = {title: split.base_name,
                  entries: [{split_id: split.id, sub_split: "in", label: "#{split.base_name} In"},
                            {split_id: split.id, sub_split: "out", label: "#{split.base_name} Out"}]}
      attributes = event.live_entry_attributes
      expect(attributes.size).to eq(splits.size)
      expect(attributes.second).to eq(expected)
    end
  end
end
