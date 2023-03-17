# frozen_string_literal: true

RSpec.shared_context "user_without_credentials" do
  let(:user) { users(:third_user) }
  let(:test_credentials) { {} }
  before { allow(user).to receive(:credentials).and_return(test_credentials) }
end

RSpec.shared_context "user_with_runsignup_credentials" do
  let(:user) { users(:third_user) }
  let(:test_credentials) { { "runsignup" => { "api_key" => "1234", "api_secret" => "2345" } } }
  before { allow(user).to receive(:credentials).and_return(test_credentials) }
end
