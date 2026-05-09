module Api
  module V1
    class PersonSerializer < ::Api::V1::BaseSerializer
      set_type :people

      PRIVATE_ATTRIBUTES = [:phone,
                            :email,
                            :birthdate].freeze

      attributes :id,
                 :gender,
                 :city,
                 :state_code,
                 :country_code

      attribute :first_name do |person, params|
        person.display_first_name_conditionally_obscured(params[:current_user])
      end

      attribute :last_name do |person, params|
        person.display_last_name_conditionally_obscured(params[:current_user])
      end

      attribute :full_name do |person, params|
        person.display_full_name_conditionally_obscured(params[:current_user])
      end

      attribute :current_age do |person, params|
        person.current_age_conditionally_obscured(params[:current_user])
      end

      PRIVATE_ATTRIBUTES.each do |att|
        attribute att, if: proc { |effort, params|
          current_user = params[:current_user]
          current_user&.authorized_to_edit?(effort)
        }
      end

      link :self, :api_v1_url

      has_many :efforts
    end
  end
end
