# frozen_string_literal: true

module Api
  module V1
    class BaseSerializer
      include ::JSONAPI::Serializer

      set_key_transform :camel_lower

      def editable
        return false unless current_user
        Pundit.policy!(current_user, object).update?
      end

      def show_personal_info?
        scope.authorized_to_edit?(object)
      end
    end
  end
end
