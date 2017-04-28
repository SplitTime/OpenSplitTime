class EffortSerializer < BaseSerializer
  attributes :id, :event_id, :participant_id, :bib_number, :first_name, :last_name, :full_name, :gender,
             :birthdate, :age, :city, :state_code, :country_code, :phone, :email, :beacon_url, :photo_url, :report_url
  link(:self) { api_v1_effort_path(object) }

  has_many :split_times, if: :split_times_loaded?

  def split_times_loaded?
    object.split_times.loaded?
  end
end