require 'rails_helper'

RSpec.describe Persist::BulkUpdateAll do
  subject { Persist::BulkUpdateAll.new(model, resources, update_fields: update_fields) }
  let(:model) { User }
  let(:resources) { build_stubbed_list(:user, 3) }
  let(:update_fields) { [:pref_distance_unit, :pref_elevation_unit] }

  describe '#initialize' do
    include_examples 'initializes with model and resources'

    context 'when no update_fields argument is given' do
      let(:update_fields) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/update_fields must be provided/)
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

      it 'updates all records and returns a descriptive response' do
        response = subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers meters), %w(kilometers feet), %w(kilometers meters)])
        expect(response.errors).to eq([])
        expect(response.message).to eq('Updated 3 users. ')
      end
    end

    context 'when a single attribute of certain records has changed' do
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers) }

      it 'updates all records and returns a descriptive response' do
        response = subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers feet), %w(kilometers feet), %w(miles feet)])
        expect(response.errors).to eq([])
        expect(response.message).to eq('Updated 3 users. ')
      end
    end

    context 'when no attributes have changed' do
      it 'updates no records and returns a response indicating the number of records given (as opposed to actually updated) has been updated' do
        response = subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to all eq(%w[miles feet])
        expect(response.errors).to eq([])
        expect(response.message).to eq('Updated 3 users. ')
      end
    end

    context 'when an error occurs' do
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers) }
      before { allow_any_instance_of(ActiveRecord::Relation).to receive(:update_all).and_raise ActiveRecord::StatementInvalid }

      it 'does not update any resource, and returns errors and a descriptive message' do
        response = subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to all eq(%w[miles feet])
        expect(response.errors.first[:title]).to eq('An ActiveRecord exception occurred')
        expect(response.message).to eq('users could not be updated. ')
      end
    end
  end
end
