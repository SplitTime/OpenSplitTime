require 'rails_helper'

describe Api::V1::OrganizationsController do
  login_admin

  let(:organization) { FactoryGirl.create(:organization) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: organization
      expect(response).to be_success
    end

    it 'returns data of a single organization' do
      get :show, id: organization
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).to eq(organization.id)
    end

    it 'returns an error if the organization does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, organization: {name: 'Test Organization'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a organization record' do
      expect(Organization.all.count).to eq(0)
      post :create, organization: {name: 'Test Organization'}
      expect(Organization.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Organization Name'} }

    it 'returns a successful json response' do
      put :update, id: organization, organization: attributes
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: organization, organization: attributes
      organization.reload
      expect(organization.name).to eq(attributes[:name])
    end

    it 'returns an error if the organization does not exist' do
      put :update, id: 0, organization: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: organization
      expect(response).to be_success
    end

    it 'destroys the organization record' do
      test_organization = organization
      expect(Organization.all.count).to eq(1)
      delete :destroy, id: test_organization
      expect(Organization.all.count).to eq(0)
    end

    it 'returns an error if the organization does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end