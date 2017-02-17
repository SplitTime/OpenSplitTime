class SplitSerializer < BaseSerializer
  attributes :id, :course_id, :distance_from_start, :vert_gain_from_start, :vert_loss_from_start,
             :kind, :base_name, :name_extensions, :location_id, :location

  belongs_to :course
end