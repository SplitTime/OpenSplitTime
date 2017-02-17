class GetEventSerializer < BaseSerializer
  attributes :id, :course_id, :organization_id, :name, :start_time, :concealed, :laps_required, :staging_id, :split_ids

  has_many :efforts
  has_many :splits
  belongs_to :course
  belongs_to :organization

  def split_ids
    object.splits.ids
  end
end