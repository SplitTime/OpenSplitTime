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
                 :flexible_geolocation,
                 :gender,
                 :id,
                 :participant_id,
                 :person_id,
                 :report_url,
                 :scheduled_start_time,
                 :state_code

      attribute :first_name do |effort, params|
        effort.display_first_name_conditionally_obscured(params[:current_user])
      end

      attribute :last_name do |effort, params|
        effort.display_last_name_conditionally_obscured(params[:current_user])
      end

      attribute :full_name do |effort, params|
        effort.display_full_name_conditionally_obscured(params[:current_user])
      end

      attribute :age do |effort, params|
        effort.display_age_conditionally_obscured(params[:current_user])
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
