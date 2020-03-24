# frozen_string_literal: true

class SplitLocationSerializer < BaseSerializer
  attributes :id, :course_name, :base_name, :distance_from_start, :latitude, :longitude, :elevation
  link(:self) { api_v1_split_path(object) }
end
