class StagingPolicy < Struct.new(:current_user, :controller)

  def get_uuid?
    current_user.present?
  end
end