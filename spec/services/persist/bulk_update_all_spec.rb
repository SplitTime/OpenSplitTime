require 'rails_helper'

RSpec.describe Persist::BulkUpdateAll do
  subject { Persist::BulkUpdateAll.new(model, resources, update_fields) }
  let(:model) { User }
  let(:update_fields) { [:pref_distance_unit, :pref_elevation_unit] }

  describe '#initialize' do
    let(:resources) { build_stubbed_list(:user, 3) }

    context 'when provided with a model, resources, and update_fields' do
      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no model argument is given' do
      let(:model) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/model must be provided/)
      end
    end

    context 'when no resources argument is given' do
      let(:resources) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/resources must be provided/)
      end
    end

    context 'when no update_fields argument is given' do
      let(:update_fields) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/update_fields must be provided/)
      end
    end

    context 'when any resource is not a member of the model class' do
      let(:resources) { [Effort.new] }

      it 'raises an error' do
        expect { subject }.to raise_error(/all resources must be members of the model class/)
      end
    end
  end

  describe '#perform!' do
    let(:resources) { create_list(:user, 3) }
    before { expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to all eq(%w[miles feet]) }

    context 'when multiple attributes of all records have changed' do
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :meters) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :feet) }
      before { resources.third.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :meters) }

      it 'updates all records' do
        subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers meters), %w(kilometers feet), %w(kilometers meters)])
      end
    end

    context 'when a single attribute of certain records has changed' do
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers) }

      it 'updates all records' do
        subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers feet), %w(kilometers feet), %w(miles feet)])
      end
    end

    context 'when no attributes have changed' do
      it 'updates no records' do
        subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to all eq(%w[miles feet])
      end
    end
  end
end
