require 'rails_helper'

RSpec.describe Persist::BulkUpsert do
  subject { Persist::BulkUpsert.new(model, resources, options) }
  let(:model) { User }
  let(:options) { {update_fields: update_fields, validate: validate} }
  let(:update_fields) { [:pref_distance_unit, :pref_elevation_unit] }
  let(:validate) { nil }

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

    context 'when any resource is not a member of the model class' do
      let(:resources) { [Effort.new] }

      it 'raises an error' do
        expect { subject }.to raise_error(/all resources must be members of the model class/)
      end
    end
  end

  describe '#perform!' do
    let(:resources) { create_list(:user, 3, created_at: Time.now - 1.day, updated_at: Time.now - 1.day) }
    before { expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to all eq(%w[miles feet]) }

    context 'when multiple attributes of all records have changed' do
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :meters) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :feet) }
      before { resources.third.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :meters) }

      it 'updates all records and sets updated_at attribute' do
        subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers meters), %w(kilometers feet), %w(kilometers meters)])
        expect(resources.map(&:created_at)).to all be_within(5.seconds).of(Time.now - 1.day)
        expect(resources.map(&:updated_at)).to all be_within(5.seconds).of(Time.now)
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

    context 'when update_fields is more limited than the changed fields' do
      let(:update_fields) { :pref_distance_unit }
      before { resources.first.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :meters) }
      before { resources.second.assign_attributes(pref_distance_unit: :kilometers, pref_elevation_unit: :feet) }

      it 'updates only those fields included in update_fields' do
        subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:pref_distance_unit, :pref_elevation_unit)).to eq([%w(kilometers feet), %w(kilometers feet), %w(miles feet)])
      end
    end

    context 'when updates are not permitted by database constraints' do
      let(:update_fields) { :email }
      before { resources.first.assign_attributes(email: nil) }
      before { resources.second.assign_attributes(email: 'user@example.com') }

      it 'does not update records and ' do
        response = subject.perform!
        resources.each(&:reload)
        expect(resources.pluck(:email)).not_to include(nil)
        expect(resources.pluck(:email)).not_to include('user@example.com')
        expect(response.message).to eq('users could not be updated. ')
        expect(response.errors.first[:title]).to eq('An ActiveRecord exception occurred')
      end
    end

    context 'when resources are not contained in the database' do
      before { resources.first.assign_attributes(id: nil, slug: nil, first_name: 'Test', last_name: 'User', email: 'test@user.com') }
      before { resources.second.assign_attributes(id: nil, slug: nil, first_name: 'Another', last_name: 'User', email: 'another@user.com') }

      it 'builds slugs and creates new records, ignoring the update_fields option' do
        expect(User.count).to eq(3)
        subject.perform!
        expect(User.count).to eq(5)
        resources.each(&:reload)
        expect(resources.pluck(:email)).to include(*%w(test@user.com another@user.com))
        expect(resources.pluck(:slug)).to include(*%w(test-user another-user))
      end
    end
  end
end
