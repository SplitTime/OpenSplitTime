require "rails_helper"

RSpec.describe Api::V1::AuthenticationController do
  before do
    create(:user, email: "test_user@example.com", password: "password", password_confirmation: "password")
  end

  describe "#create" do
    it "returns a successful 200 response" do
      post :create, params: {user: {email: "test_user@example.com", password: "password"}}
      expect(response).to be_successful
    end

    it "returns a valid JSON web token" do
      post :create, params: {user: {email: "test_user@example.com", password: "password"}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response["token"]
      expect(token).not_to be_nil
      expect { JsonWebToken.decode(token) }.not_to raise_error
    end

    it "returns a valid user id" do
      post :create, params: {user: {email: "test_user@example.com", password: "password"}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response["token"]
      payload = JsonWebToken.decode(token)
      user = User.last
      expect(payload["sub"]).to eq(user.id)
    end

    it "returns a valid expiration" do
      post :create, params: {user: {email: "test_user@example.com", password: "password"}}
      parsed_response = JSON.parse(response.body)
      token = parsed_response["token"]
      payload = JsonWebToken.decode(token)
      expect(Time.at(payload["exp"]))
          .to be_within(1.minute).of(Time.current + ::OstConfig.jwt_duration)
    end

    it "returns an error if the email does not exist" do
      post :create, params: {user: {email: "nonexistent@example.com", password: "password"}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["errors"]).to include(/Invalid email or password/)
      expect(response).to be_bad_request
    end

    it "returns an error if the password is incorrect" do
      post :create, params: {user: {email: "test_user@example.com", password: "incorrect"}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["errors"]).to include(/Invalid email or password/)
      expect(response).to be_bad_request
    end
  end
end
