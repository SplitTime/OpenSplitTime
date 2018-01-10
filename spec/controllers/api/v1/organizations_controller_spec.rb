require 'rails_helper'

RSpec.describe Api::V1::OrganizationsController do
  login_admin

  let(:organization) { create(:organization) }

  describe '#index' do
    before do
      create(:organization, name: 'Bravo', description: 'Fabulous')
      create(:organization, name: 'Charlie', description: 'Beautiful')
      create(:organization, name: 'Alpha', description: 'Beautiful')
      create(:organization, name: 'Delta', description: 'Gorgeous')
    end

    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns each organization that the current_user is authorized to edit' do
      get :index
      expect(response.status).to eq(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].size).to eq(4)
      expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(Organization.all.map(&:id))
    end

    it 'sorts properly in ascending order based on a provided sort parameter' do
      expected = %w(Alpha Bravo Charlie Delta)
      get :index, params: {sort: 'name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end

    it 'sorts properly in descending order based on a provided sort parameter with a minus sign' do
      expected = %w(Delta Charlie Bravo Alpha)
      get :index, params: {sort: '-name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end

    it 'sorts properly on multiple fields' do
      expected = %w(Alpha Charlie Bravo Delta)
      get :index, params: {sort: 'description,name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: organization}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single organization' do
      get :show, params: {id: organization}
      expect(response.body).to be_jsonapi_response_for('organizations')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(organization.id)
    end

    it 'returns an error if the organization does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, params: {data: {type: 'organizations', attributes: {name: 'Test Organization'} }}
      expect(response.body).to be_jsonapi_response_for('organizations')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a organization record' do
      expect(Organization.all.count).to eq(0)
      post :create, params: {data: {type: 'organizations', attributes: {name: 'Test Organization'} }}
      expect(Organization.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Organization Name'} }

    it 'returns a successful json response' do
      put :update, params: {id: organization, data: {type: 'organizations', attributes: attributes }}
      expect(response.body).to be_jsonapi_response_for('organizations')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: organization, data: {type: 'organizations', attributes: attributes }}
      organization.reload
      expect(organization.name).to eq(attributes[:name])
    end

    it 'returns an error if the organization does not exist' do
      put :update, params: {id: 0, data: {type: 'organizations', attributes: attributes }}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: organization}
      expect(response.status).to eq(200)
    end

    it 'destroys the organization record' do
      test_organization = organization
      expect(Organization.all.count).to eq(1)
      delete :destroy, params: {id: test_organization}
      expect(Organization.all.count).to eq(0)
    end

    it 'returns an error if the organization does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
