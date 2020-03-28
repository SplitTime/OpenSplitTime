# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimePointWithEffortRank, type: :model do
  describe '.execute_query' do
    subject { described_class.execute_query(effort) }

    context 'when given an effort id that coincides with other efforts in aid' do
      let(:effort) { efforts(:hardrock_2015_chris_rempel) }
      let(:grouse) { splits(:hardrock_ccw_grouse) }
      let(:subject_time_point) { TimePoint.new(1, grouse.id, in_bitkey) }
      it 'returns rows containing time_points with effort ranking information' do
        expect(subject.size).to eq(14)
        grouse_in_tpwer = subject.find { |tpwer| tpwer.time_point == subject_time_point }
        expect(grouse_in_tpwer.rank).to eq(12)
        expect(grouse_in_tpwer.effort_ids_ahead).to match_array([7, 8, 15, 25, 29, 24, 20, 47, 141, 50, 59])
      end
    end
  end
end
