module Api
  module V1
    class EffortSerializer < ::Api::V1::BaseSerializer
      set_type :efforts

      PRIVATE_ATTRIBUTES = [:phone,
                            :email,
                            :birthdate,
                            :emergency_contact,
                            :emergency_phone].freeze

      attributes :beacon_url,
                 :bib_number,
                 :city,
                 :country_code,
                 :event_id,
                 :first_name,
                 :flexible_geolocation,
                 :full_name,
                 :gender,
                 :id,
                 :last_name,
                 :participant_id,
                 :person_id,
                 :report_url,
                 :scheduled_start_time,
                 :state_code

      attribute :age do |effort, params|
        if effort.person&.hide_age? && !params[:current_user]&.authorized_to_edit?(effort)
          nil
        else
          effort.age
        end
      end

      PRIVATE_ATTRIBUTES.each do |att|
        attribute att, if: proc { |effort, params|
          current_user = params[:current_user]
          current_user&.authorized_to_edit?(effort)
        }
      end

      link :self, :api_v1_url

      has_many :split_times, if: proc { |effort| effort.split_times.loaded? }
    end
  end
end
