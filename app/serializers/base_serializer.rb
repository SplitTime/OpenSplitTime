class BaseSerializer < ActiveModel::Serializer

  def editable
    Pundit.policy!(current_user, object).update?
  end
end