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

      [:first_name, :last_name].each do |att|
        attribute att do |person, params|
          if params[:current_user]&.authorized_to_edit?(person) || !person.obscure_name?
            person.public_send(att)
          else
            "#{person.public_send(att)&.first}."
          end
        end
      end

      attribute :full_name do |person, params|
        if params[:current_user]&.authorized_to_edit?(person) || !person.obscure_name?
          person.full_name
        else
          person.initials
        end
      end

      attribute :current_age do |person, params|
        if person.hide_age? && !params[:current_user]&.authorized_to_edit?(person)
          nil
        else
          person.current_age_from_birthdate || person.current_age_approximate
        end
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
