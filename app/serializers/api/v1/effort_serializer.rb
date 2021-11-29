# frozen_string_literal: true

module Api
  module V1
    class EffortSerializer < ::Api::V1::BaseSerializer
      set_type :efforts

      PRIVATE_ATTRIBUTES = [:phone,
                            :email,
                            :birthdate,
                            :emergency_contact,
                            :emergency_phone]

      attributes :age,
                 :beacon_url,
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

      PRIVATE_ATTRIBUTES.each do |att|
        attribute att, if: Proc.new { |effort, params|
          current_user = params[:current_user]
          current_user&.authorized_to_edit?(effort)
        }
      end

      link :self, :api_v1_url

      has_many :split_times, if: Proc.new { |effort| effort.split_times.loaded? }
    end
  end
end
