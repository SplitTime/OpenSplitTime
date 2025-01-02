# current_user is the only user that can create, update, or destroy a credential
# so we don't need to check the record for any of these actions
class CredentialPolicy < ApplicationPolicy
  def post_initialize(_)
  end

  def create?
    user.present?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
