# frozen_string_literal: true

class CourseParameters < BaseParameters

  def self.permitted
    [:id, :organization_id, :slug, :name, :description, :distance, :distance_preferred, :vert_gain, :vert_gain_preferred,
     :vert_loss, :vert_loss_preferred, :next_start_time, :next_start_time_local, :gpx, :delete_gpx,
     splits_attributes: [*SplitParameters.permitted]]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
