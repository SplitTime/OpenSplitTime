# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EffortsTogetherInAid, type: :model do
  describe '.execute_query' do
    subject { described_class.execute_query(effort.id) }

    context 'when given an effort id that coincides with other efforts in aid' do
      let(:effort) { efforts(:hardrock_2015_chris_rempel) }
      let(:grouse) { splits(:hardrock_ccw_grouse) }
      it 'returns rows containing effort ids together in aid at various lap splits' do
        expect(subject.size).to eq(4)
        grouse_etia = subject.find { |etia| etia.lap == 1 && etia.split_id == grouse.id }
        expect(grouse_etia.together_effort_ids).to match_array([31, 50, 59, 141])
      end
    end
  end
end
