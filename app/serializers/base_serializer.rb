# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer

  def editable
    Pundit.policy!(current_user, object).update?
  end

  def show_personal_info?
    scope.authorized_to_edit?(object)
  end
end
