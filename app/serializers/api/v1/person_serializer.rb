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
          if person.obscure_name? && !params[:current_user]&.authorized_to_edit?(person)
            "#{person.public_send(att)&.first}."
          else
            person.public_send(att)
          end
        end
      end

      attribute :full_name do |person, params|
        if person.obscure_name? && !params[:current_user]&.authorized_to_edit?(person)
          person.initials
        else
          [person.first_name, person.last_name].compact_blank.join(" ")
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
