class PersonPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :person

  def post_initialize(person)
    @person = person
  end

  def new?
    user.admin?
  end

  def create?
    user.admin?
  end

  def edit?
    user.admin? || user.avatar == person
  end

  def update?
    edit?
  end

  def destroy?
    user.admin?
  end

  def avatar_claim?
    user.authorized_to_claim?(person)
  end

  def merge?
    user.admin?
  end

  def combine?
    user.admin?
  end
end
