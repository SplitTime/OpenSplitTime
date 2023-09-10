# frozen_string_literal: true

RSpec.shared_context "user_without_credentials" do
  let(:user) { users(:third_user) }
  before { user.credentials.destroy_all }
end

RSpec.shared_context "user_with_credentials" do
  let(:user) { users(:third_user) }
end
