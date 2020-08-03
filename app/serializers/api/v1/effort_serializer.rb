# frozen_string_literal: true

module Api
  module V1
    class EffortSerializer < ::Api::V1::BaseSerializer
      attributes :id, :event_id, :person_id, :participant_id, :bib_number, :first_name, :last_name, :full_name, :gender,
                 :age, :city, :state_code, :country_code, :flexible_geolocation, :beacon_url, :report_url, :scheduled_start_time
      %i[phone email birthdate emergency_contact emergency_phone].each { |att| attribute att, if: :show_personal_info? }

      link(:self) { api_v1_effort_path(object) }

      has_many :split_times, if: :split_times_loaded?

      def split_times_loaded?
        object.split_times.loaded?
      end
    end
  end
end
