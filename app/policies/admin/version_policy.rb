# frozen_string_literal: true

module Admin
  class VersionPolicy < ApplicationPolicy
    attr_reader :version

    def post_initialize(version)
      @version = version
    end

    def show?
      user.admin?
    end

    def index?
      user.admin?
    end
  end
end
