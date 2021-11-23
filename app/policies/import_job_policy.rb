# frozen_string_literal: true

class ImportJobPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :import_job

  def post_initialize(import_job)
    @import_job = import_job
  end

  def index?
    user.admin? || (import_job.user == user)
  end

  def new?
    user.admin? || (import_job.user == user)
  end

  def create?
    user.admin? || (import_job.user == user)
  end

  def destroy?
    user.admin? || (import_job.user == user)
  end
end
