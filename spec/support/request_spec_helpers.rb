module RequestSpecHelpers
  include Warden::Test::Helpers

  def self.included(base)
    base.before(:each) { Warden.test_mode! }
    base.after(:each) { Warden.test_reset! }
  end

  def via_login_and_jwt(&block)
    %w(login jwt).each do |strategy|
      context "with #{strategy} strategy" do
        let(:request_spec_admin) { FactoryBot.create(:admin) }

        case strategy
        when 'login'
          login_as_admin
        when 'jwt'
          add_jwt_headers
        else
          raise RuntimeError, "Strategy #{strategy} is not recognized"
        end

        module_eval(&block)
      end
    end
  end

  def add_jwt_headers
    before { request.headers.merge!(headers) }
    let(:headers) { {"Authorization" => "bearer #{token}"} }
    let(:token) { JsonWebToken.encode(sub: request_spec_admin.id) }
  end

  def login_as_admin
    before { sign_in request_spec_admin }
    after { sign_out request_spec_admin }
  end

  def sign_in(resource)
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end

  RSpec.configure do |config|
    config.extend self, type: :controller
  end
end
