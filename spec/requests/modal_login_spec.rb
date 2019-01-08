# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Modal login", type: :request do
  subject(:make_request) { post '/users/sign_in', params: params, xhr: true }

  let(:params) { {'user' => {'email' => email, 'password' => password}} }

  let!(:user) { create(:user, email: valid_email, password: valid_password, password_confirmation: valid_password) }
  let(:valid_email) { 'jane@example.com' }
  let(:valid_password) { '12345678' }

  let(:invalid_email) { 'joe@example.com' }
  let(:invalid_password) { '11111111' }

  context 'with a valid email and password' do
    let(:email) { valid_email }
    let(:password) { valid_password }

    it 'logs in the user and remains on the page' do
      make_request

      expect(response.status).to eq(200)
    end
  end

  context 'with an invalid email' do
    let(:email) { invalid_email }
    let(:password) { valid_password }

    it 'returns 200 but does not attempt to redirect to the sign_in page' do
      make_request

      expect(response.status).to eq(200)
      expect(response.body).to include('Invalid email or password.')
      expect(response).not_to redirect_to('/users/sign_in')
    end
  end

  context 'with an invalid password' do
    let(:email) { valid_email }
    let(:password) { invalid_password }

    it 'returns 200 but does not attempt to redirect to the sign_in page' do
      make_request

      expect(response.status).to eq(200)
      expect(response.body).to include('Invalid email or password.')
      expect(response).not_to redirect_to('/users/sign_in')
    end
  end
end
