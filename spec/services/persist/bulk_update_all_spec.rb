require 'rails_helper'

RSpec.describe BulkUpdateAll do
  subject { Persist::BulkUpdateAll.perform!(model, resources, update_fields) }

  describe '#initialize' do
    context 'when provided with a model, resources, and update_fields' do
      let(:model) { User }
      let(:resources) { create_list(:user, 3) }
      let(:update_fields) { [:pref_distance_unit, :pref_elevation_unit] }
      before { resources.first.assign_attributes(pref_distance_unit: :meters, pref_elevation_unit: :meters) }
      before { resources.second.assign_attributes(pref_distance_unit: :meters, pref_elevation_unit: :meters) }
      before { resources.third.assign_attributes(pref_distance_unit: :meters, pref_elevation_unit: :meters) }

      it 'calls Model#update_all to update each field with the modified values' do

      end
    end
  end
end