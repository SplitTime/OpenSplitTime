require 'spec_helper'

shared_examples_for 'auditable' do
  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }

  describe 'before validation' do
    let(:current_user) { FactoryGirl.build_stubbed(:user, id: 1) }
    let(:existing_user) { FactoryGirl.build_stubbed(:user, id: 2) }

    it 'adds the current user id to created_by and updated_by' do
      allow(User).to receive(:current).and_return(current_user)
      resource = FactoryGirl.build(model_name, created_by: nil, updated_by: nil)
      resource.valid?
      expect(resource.created_by).to eq(current_user.id)
    end

    it 'does not change created_by or updated_by if they already exist' do
      allow(User).to receive(:current).and_return(current_user)
      resource = FactoryGirl.build(model_name, created_by: existing_user.id, updated_by: existing_user.id)
      resource.valid?
      expect(resource.created_by).to eq(existing_user.id)
    end

    it 'does not change created_by or updated_by if User.current is not available' do
      allow(User).to receive(:current).and_return(nil)
      resource = FactoryGirl.build(model_name, created_by: nil, updated_by: nil)
      resource.valid?
      expect(resource.created_by).to eq(nil)
    end
  end
end