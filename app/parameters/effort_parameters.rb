# frozen_string_literal: true

class EffortParameters < BaseParameters

  def self.permitted_query
    enriched_query
  end

  def self.enriched_query
    [:id, :slug, :event_id, :person_id, :participant_id, :wave, :bib_number, :city, :state_code, :age,
     :created_at, :updated_at, :created_by, :updated_by, :first_name, :last_name, :gender,
     :country_code, :birthdate, :data_status, :start_offset,
     :beacon_url, :report_url, :photo, :laps_required, :event_start_time,
     :final_split_name, :final_lap_distance, :final_lap, :final_split_id, :final_bitkey, :final_time,
     :final_split_time_id, :stopped_split_time_id, :stopped_lap, :stopped_split_id, :stopped_bitkey,
     :stopped_time, :final_lap_complete, :course_distance, :started, :laps_started, :laps_finished,
     :final_distance, :finished, :stopped, :dropped, :overall_rank, :gender_rank, :full_name, :bio_historic,
     :prior_to_here_info, :stopped_here_info, :dropped_here_info, :recorded_here_info, :after_here_info,
     :expected_here_info, :due_next_info, :last_reported_info, :state_and_country]
  end

  def self.permitted
    [:id, :slug, :event_id, :person_id, :participant_id, :first_name, :last_name, :gender, :wave, :bib_number, :age, :birthdate,
     :city, :state_code, :country_code, :finished, :start_time, :start_offset,
     :beacon_url, :report_url, :photo, :phone, :email, :checked_in, :emergency_contact, :emergency_phone,
     split_times_attributes: [*SplitTimeParameters.permitted]]
  end

  def self.mapping
    {first: :first_name, firstname: :first_name, last: :last_name, lastname: :last_name, name: :full_name, state: :state_code,
     country: :country_code, sex: :gender, bib: :bib_number, :"bib_#" => :bib_number, dob: :birthdate,
     emergency_name: :emergency_contact}
  end

  def self.unique_key
    [:event_id, :first_name, :last_name, :birthdate]
  end
end
