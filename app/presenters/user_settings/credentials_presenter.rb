# frozen_string_literal: true

module UserSettings
  class CredentialsPresenter
    def initialize(user)
      @user = user
    end

    attr_reader :user

    def existing_user_services
      @existing_user_services ||= user.credentials.pluck(:service_identifier).uniq.map do |service_identifier|
        Connectors::Service::BY_IDENTIFIER[service_identifier]
      end
    end

    def not_existing_user_services
      @not_existing_user_services ||= Connectors::Service.all - existing_user_services
    end
  end
end
