# frozen_string_literal: true

module Connectors
  class ServicePolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def post_initialize
      end
    end

    attr_reader :organization

    def post_initialize(organization)
      verify_authorization_was_delegated(organization, ::Connectors::Service)
      @organization = organization
    end

    def preview_sync?
      user.authorized_to_edit?(organization)
    end

    def sync?
      preview_sync?
    end
  end
end
