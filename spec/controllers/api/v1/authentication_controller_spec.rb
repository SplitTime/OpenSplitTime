require 'rails_helper'

describe Api::V1::AuthenticationController do
  before do
    FactoryGirl.create(:user, email: 'user@example.com', password: 'password', password_confirmation: 'password')
  end

  describe '#create' do
    it 'returns a successful 200 response' do
      post :create, params: {user: {email: 'user@example.com', password: 'password'}}
      expect(response).to be_success
    end

    it 'returns a valid JSON web token' do
      post :create, params: {user: {email: 'user@example.com', password: 'password'}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response['token']
      expect(token).not_to be_nil
      expect { JsonWebToken.decode(token) }.not_to raise_error
    end

    it 'returns a valid user id' do
      post :create, params: {user: {email: 'user@example.com', password: 'password'}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response['token']
      payload = JsonWebToken.decode(token)
      user = User.last
      expect(payload['sub']).to eq(user.id)
    end

    it 'returns a valid expiration' do
      post :create, params: {user: {email: 'user@example.com', password: 'password'}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response['token']
      payload = JsonWebToken.decode(token)
      expect(Time.at(payload['exp']))
          .to be_within(1.minute).of(Time.current + Rails.application.secrets.jwt_duration)
    end

    it 'returns an error if the email does not exist' do
      post :create, params: {user: {email: 'nonexistent@example.com', password: 'password'}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/Invalid email or password/)
      expect(response).to be_bad_request
    end

    it 'returns an error if the password is incorrect' do
      post :create, params: {user: {email: 'user@example.com', password: 'incorrect'}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/Invalid email or password/)
      expect(response).to be_bad_request
    end

    context 'when params[:durable] is equal to ENV["DURABLE_JWT_CODE"]' do
      it 'returns a valid long-duration expiration' do
        post :create, params: {user: {email: 'user@example.com', password: 'password'}, durable: ENV['DURABLE_JWT_CODE']}
        parsed_response = JSON.parse(response.body)
        token = parsed_response['token']
        payload = JsonWebToken.decode(token)
        expect(Time.at(payload['exp']))
            .to be_within(1.minute).of(Time.current + Rails.application.secrets.jwt_duration_long)
      end
    end

    context 'when params[:durable] is provided but is not equal to ENV["DURABLE_JWT_CODE"]' do
      it 'returns an error' do
        post :create, params: {user: {email: 'user@example.com', password: 'password'}, durable: 'invalid_code'}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to include(/Invalid durable code/)
        expect(response).to be_bad_request
      end
    end
  end
end
