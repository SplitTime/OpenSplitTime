require "rails_helper"

RSpec.describe "Modal login", type: :request do
  let!(:user) { create(:user, email: email, password: password, password_confirmation: password) }
  let(:email) { 'jane@example.com' }
  let(:password) { '12345678' }

  let(:invalid_email) { 'joe@example.com' }
  let(:invalid_password) { '11111111' }

  context 'with a valid username and password' do
    it 'logs in the user and remains on the page' do

    end
  end
  it "creates a Widget and redirects to the Widget's page" do
    get "/widgets/new"
    expect(response).to render_template(:new)

    post "/widgets", widget: {name: "My Widget"}

    expect(response).to redirect_to(assigns(:widget))
    follow_redirect!

    expect(response).to render_template(:show)
    expect(response.body).to include("Widget was successfully created.")
  end

  it "does not render a different template" do
    get "/widgets/new"
    expect(response).to_not render_template(:show)
  end
end