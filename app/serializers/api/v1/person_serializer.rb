# frozen_string_literal: true

module Api
  module V1
    class PersonSerializer < ::Api::V1::BaseSerializer
      set_type :people

      PRIVATE_ATTRIBUTES = [:phone,
                            :email,
                            :birthdate]

      attributes :id,
                 :first_name,
                 :last_name,
                 :full_name,
                 :gender,
                 :current_age,
                 :city,
                 :state_code,
                 :country_code

      PRIVATE_ATTRIBUTES.each do |att|
        attribute att, if: Proc.new { |effort, params|
          current_user = params[:current_user]
          current_user&.authorized_to_edit?(effort)
        }
      end

      link :self, :api_v1_url

      has_many :efforts
    end
  end
end
