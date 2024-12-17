# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::UsersController do
  let(:user) { users(:third_user) }
  let(:type) { "users" }

  describe "#current" do
    let(:make_request) { get :current }

    via_login_and_jwt do
      it "returns a successful json response" do
        make_request
        expect(response.status).to eq(200)
      end

      it "returns data of the current user" do
        make_request
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["data"]["id"].to_i).to eq(subject.current_user.id)
      end
    end
  end
end
