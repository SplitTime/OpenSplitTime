require "rails_helper"

RSpec.describe EffortsTogetherInAid, type: :model do
  describe ".execute_query" do
    subject { described_class.execute_query(effort_id: effort.id) }

    context "when given an effort id that coincides with other efforts in aid" do
      let(:effort) { efforts(:hardrock_2015_chris_rempel) }
      let(:grouse) { splits(:hardrock_ccw_grouse) }
      it "returns rows containing effort ids together in aid at various lap splits" do
        expect(subject.size).to eq(4)
        grouse_etia = subject.find { |etia| etia.lap == 1 && etia.split_id == grouse.id }
        expected_ids = %i[hardrock_2015_gilberto_mckenzie hardrock_2015_cedric_windler hardrock_2015_rachelle_eichmann hardrock_2015_irvin_harber].map { |label| efforts(label).id }
        expect(grouse_etia.together_effort_ids).to match_array(expected_ids)
      end
    end
  end
end
